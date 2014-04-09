require('dotenv').load()

debug   = require('debug')('emojitrack-sse:server')
redis   = require('redis')
url     = require('url')
app     = require('express')()
http    = require('http')
server  = http.Server(app)

to_bool = (s) -> s and !!s.match(/^(true|t|yes|y|1)$/i)
VERBOSE = to_bool(process.env.VERBOSE) || false

ScorePacker    = require('./lib/scorePacker')
ConnectionPool = require('./lib/connectionPool')

###
# stand up services
###
# http.globalAgent.maxSockets = 1024

app.configure 'production', ->
  # trust x forwarded for headers from proxy (heroku routing)
  app.enable('trust proxy')
  # enable new relic reporting
  require('newrelic')

port = process.env.PORT || 8000
server.listen port, ->
  console.log('Listening on ' + port)

###
# routing event stuff
###
rawClients     = new ConnectionPool()
epsClients     = new ConnectionPool()
detailClients  = new ConnectionPool()
#kiosk_clients = new ConnectionPool()

sse_headers = (req,res) ->
  req.socket.setTimeout(Infinity)
  res.writeHead(200, {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  })
  res.write('\n')

provision_client = (req,res,channel,connectionPool) ->
  sse_headers(req,res)
  console.log "CONNECT:\t#{req.path}\tby #{req.ip}" if VERBOSE
  clientId = connectionPool.add(channel,req,res)
  req.on 'close', ->
    connectionPool.remove(clientId)
    console.log "DISCONNECT:\t#{req.path}\tby #{req.ip}" if VERBOSE

app.get '/subscribe/raw', (req, res) ->
  provision_client req,res,'/raw',rawClients

app.get '/subscribe/eps', (req, res) ->
  provision_client req,res,'/eps',epsClients

app.get '/subscribe/details/:id', (req, res) ->
  provision_client req,res,"/details/#{req.params.id}",detailClients


###
# redis event stuff
###
redis_connect = ->
  rtg = url.parse(process.env.REDIS_URL)
  rclient = redis.createClient(rtg.port, rtg.hostname)
  rclient.auth(rtg.auth.split(":")[1])
  rclient

redisStreamClient = redis_connect()
redisStreamClient.psubscribe('stream.score_updates')
redisStreamClient.psubscribe('stream.tweet_updates.*')
# redis.psubscribe('stream.interaction.*')

sc = new ScorePacker(17) #17ms
sc.on 'expunge', (scores) ->
  epsClients.broadcast {data: JSON.stringify(scores), event: null, channel: '/eps'}

redisStreamClient.on 'pmessage', (pattern, channel, msg) ->

  if channel == 'stream.score_updates'
    #broadcast to raw stream
    rawClients.broadcast {data: msg, event: null, channel: '/raw'}
    #send to score packer for eps rollup stream
    sc.increment(msg)

  else if channel.indexOf('stream.tweet_updates.') == 0 #.startsWith
    channelID = channel.split('.')[2]
    detailClients.broadcast {
                              data: msg
                              event: "/details/#{channelID}"
                              channel: "/details/#{channelID}"
                            }

  # else if 'stream.interaction.*' #TODO: reimplement me when we need kiosk mode again


###
# monitoring
###
STREAM_STATUS_REDIS_KEY = 'admin_stream_status'
STREAM_STATUS_UPDATE_RATE = 5000

server_node_name = ->
  platform = 'node'
  environment = process.env.NODE_ENV || 'development'
  dyno = process.env.DYNO || 'unknown'
  "#{platform}-#{environment}-#{dyno}"

status_report = ->
  {
    node: server_node_name()
    reported_at: Date.now()
    connections: {
      stream_raw: rawClients.status_hash()
      stream_eps: epsClients.status_hash()
      stream_detail: detailClients.status_hash()
    }
  }

app.get '/subscribe/admin/node.json', (req, res) ->
  res.json status_report()

# needs to be on a different redis client than SUBSCRIBE
redisReportingClient = redis_connect()
send_report = ->
  redisReportingClient.hset(
    STREAM_STATUS_REDIS_KEY,
    server_node_name(),
    JSON.stringify( status_report() )
  )
setInterval send_report, STREAM_STATUS_UPDATE_RATE
#TODO: only send the above on staging or prod
