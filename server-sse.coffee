debug   = require('debug')('emojitrack-sse:server')
app     = require('express')()
http    = require('http')
server  = http.Server(app)

config         = require('./lib/config')
ScorePacker    = require('./lib/scorePacker')
ConnectionPool = require('./lib/connectionPool')
Monitor        = require('./lib/monitor')

###
# stand up services
###
# http.globalAgent.maxSockets = 1024

app.configure 'production', ->
  # trust x forwarded for headers from proxy (heroku routing)
  app.enable('trust proxy')
  # enable new relic reporting
  require('newrelic')

server.listen config.PORT, ->
  console.log('Listening on ' + config.PORT)

###
# routing event stuff
###
rawClients     = new ConnectionPool()
epsClients     = new ConnectionPool()
detailClients  = new ConnectionPool()
#kiosk_clients = new ConnectionPool()

provision_client = (req,res,channel,connectionPool) ->
  console.log "CONNECT:\t#{req.path}\tby #{req.ip}" if config.VERBOSE
  clientId = connectionPool.add(channel,req,res)
  req.on 'close', ->
    connectionPool.remove(clientId)
    console.log "DISCONNECT:\t#{req.path}\tby #{req.ip}" if config.VERBOSE

app.get '/subscribe/raw', (req, res) ->
  provision_client req,res,'/raw',rawClients
  #TODO: move this logic into class such that rawClients.provision_client foo

app.get '/subscribe/eps', (req, res) ->
  provision_client req,res,'/eps',epsClients

app.get '/subscribe/details/:id', (req, res) ->
  provision_client req,res,"/details/#{req.params.id}",detailClients


###
# redis event stuff
###
redisStreamClient = config.redis_connect()
redisStreamClient.psubscribe('stream.score_updates')
redisStreamClient.psubscribe('stream.tweet_updates.*')
# redis.psubscribe('stream.interaction.*')

sc = new ScorePacker(17) #17ms
sc.on 'expunge', (scores) ->
  epsClients.broadcast {data: JSON.stringify(scores), event: null, channel: '/eps'}

redisStreamClient.on 'pmessage', (pattern, channel, msg) ->

  # TODO:  no pattern really, make this a normal subscribe
  if channel == 'stream.score_updates'
    #broadcast to raw stream
    rawClients.broadcast {data: msg, event: null, channel: '/raw'}
    #send to score packer for eps rollup stream
    sc.increment(msg)

  # TODO: we can check pattern here instead
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
monitor = new Monitor(rawClients,epsClients,detailClients)
app.get '/subscribe/admin/node.json', (req, res) ->
  res.json monitor.status_report()
