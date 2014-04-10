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
scorepacker = new ScorePacker(17) #17ms

redisStreamClient.subscribe('stream.score_updates')
redisStreamClient.psubscribe('stream.tweet_updates.*')
# redis.psubscribe('stream.interaction.*')

redisStreamClient.on 'message', (channel, msg) ->
  # in theory we could check the channel, but since we are only subscribed to one
  # let's not bother and save an unncessary comparison operation.  in future may be necessary.
  rawClients.broadcast {data: msg, event: null, channel: '/raw'}
  scorepacker.increment(msg) #send to score packer for eps rollup stream

redisStreamClient.on 'pmessage', (pattern, channel, msg) ->
  if pattern == 'stream.tweet_updates.*'
    channelID = channel.split('.')[2]
    detailClients.broadcast {
                              data: msg
                              event: "/details/#{channelID}"
                              channel: "/details/#{channelID}"
                            }
  # else if pattern == 'stream.interaction.*'
  #TODO: reimplement me when we need kiosk mode again

scorepacker.on 'expunge', (scores) ->
  epsClients.broadcast {data: JSON.stringify(scores), event: null, channel: '/eps'}


###
# monitoring
###
monitor = new Monitor(rawClients,epsClients,detailClients)
app.get '/subscribe/admin/node.json', (req, res) ->
  res.json monitor.status_report()
