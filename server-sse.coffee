# ### some leftover ruby stuff here
# log_connect = (stream_obj) ->
#    "STREAM: connect for #{stream_obj.request_path} from #{request.ip}" if VERBOSE
#   REDIS.PUBLISH 'stream.admin.connect', stream_obj.to_json
#
# log_disconnect = (stream_obj) ->
#   console.log "STREAM: disconnect for #{stream_obj.request_path} from #{request.ip}" if VERBOSE
#   REDIS.PUBLISH 'stream.admin.disconnect', stream_obj.to_json
#
# logEvent = (eventName, streamObject) ->
#   console.log "STREAM: disconnect for #{stream_obj.request_path} from #{request.ip}" if VERBOSE
#   REDIS.PUBLISH "stream.admin.#{eventName}", stream_obj.to_json

redis   = require('redis')
url     = require('url')
app     = require('express')()
server  = require('http').Server(app)
dotenv  = require('dotenv')
dotenv.load()

debug   = require('debug')('emojitrack-sse:server')

#should be in config...
VERBOSE = true #process.env.VERBOSE || false #TODO fixme from ruby

ScorePacker = require('./lib/ScorePacker')
ConnectionPool = require('./lib/connectionPool')

###
# stand up services
###
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
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  })
  res.write('\n')

provision_client = (req,res,channel,connectionPool) ->
  sse_headers(req,res)
  clientId = connectionPool.add(channel,req,res)
  req.on 'close', -> connectionPool.remove(clientId)

app.get '/subscribe/raw', (req, res) ->
  provision_client req,res,'/raw',rawClients

app.get '/subscribe/eps', (req, res) ->
  provision_client req,res,'/eps',epsClients

app.get '/subscribe/details/:id', (req, res) ->
  provision_client req,res,"/details/#{id}",detailClients


###
# redis event stuff
###
# clientControl = redis.createClient() #need a second connection so main one is only used for sub

rtg = url.parse(process.env.REDIS_URL)
redisStreamClient = redis.createClient(rtg.port, rtg.hostname)
redisStreamClient.auth(rtg.auth.split(":")[1])

redisStreamClient.psubscribe('stream.score_updates')
redisStreamClient.psubscribe('stream.tweet_updates.*')
# redis.psubscribe('stream.interaction.*')

sc = new ScorePacker(17) #17ms
sc.on 'expunge', (scores) ->
  epsClients.broadcast {data: JSON.stringify(scores), event: null, namespace: null}

redisStreamClient.on 'pmessage', (pattern, channel, msg) ->

  if channel == 'stream.score_updates'
    #broadcast to raw stream
    rawClients.broadcast {data: msg, event: null, namespace: null}
    #send to score packer for eps rollup stream
    sc.increment(msg)

  else if channel.indexOf('stream.tweet_updates.') == 0 #.startsWith
    channelID = channel.split('.')[2]
    detailClients.broadcast {
                              data: msg
                              event: "/details/#{channelID}"
                              namespace: "/details/#{channelID}"
                            }

  # else if 'stream.interaction.*' #TODO: reimplement me when we need kiosk mode again




###
# logging event stuff
###
# if VERBOSE
  # raw = io.of('/raw').on 'connection', ->
  #   console.log "connection to raw"
  #
  # raw = io.of('/details').on 'connection', ->
  #   console.log "connection to details"

  # raw = io.on 'connection', ->
    # console.log "generic connection"
    # console.log io.sockets.sockets


###
# monitoring
###
status_report = ->
  {
    node: null
    reported_at: Date.now()
    connections: {
      stream_raw: rawClients.status_hash()
      stream_eps: epsClients.status_hash()
      stream_detail: detailClients.status_hash()
    }
  }

app.get '/subscribe/admin/node.json', (req, res) ->
  res.json status_report()

# TODO: periodic task to report to redis
