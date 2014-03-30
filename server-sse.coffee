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

ScorePacker = require('./lib/ScorePacker')

###
# stand up services
###
port = process.env.PORT || 8000
server.listen port, ->
  console.log('Listening on ' + port)


###
# routing event stuff
###
clients = new ConnectionPool()

sse_headers = (req,res) ->
  req.socket.setTimeout(Infinity)
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  })
  res.write('\n')

provision_client = (req,res,channel) ->
  sse_headers(req,res)
  clientId = clients.add(clientId,channel,req,res)
  req.on 'close', -> clients.remove(clientId)

app.get '/subscribe/raw', (req, res) ->
  provision_client req,res,'/raw'

app.get '/subscribe/eps', (req, res) ->
  provision_client req,res,'/eps'

app.get '/subscribe/details/:id', (req, res) ->
  provision_client req,res,"/details/#{id}"


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
  clients.broadcast "/eps", JSON.stringify( scores )

redisStreamClient.on 'pmessage', (pattern, channel, msg) ->
  if channel == 'stream.score_updates'
    clients.broadcast "/raw", msg #TODO: maybe disable now that we dont use?
    sc.increment(msg)
  else if channel.indexOf('stream.tweet_updates.') == 0 #.startsWith
    channelID = channel.split('.')[2]
    clients.broadcast "/details/#{channelID}", msg, "/details/#{channelID}"
  # else if 'stream.interaction.*'



###
# how we write to all da clients
###


###
# logging event stuff
###
VERBOSE = true #process.env.VERBOSE || false #TODO fixme from ruby
# if VERBOSE
  # raw = io.of('/raw').on 'connection', ->
  #   console.log "connection to raw"
  #
  # raw = io.of('/details').on 'connection', ->
  #   console.log "connection to details"

  # raw = io.on 'connection', ->
    # console.log "generic connection"
    # console.log io.sockets.sockets


# i think the above only gets fired once per websocket connection and namespaces multiplexed
# look for a 'subscribe' type one?

###
# monitoring
#  see http://faye.jcoglan.com/node/monitoring.html
###
# bayeux.on 'handshake' -> null
# bayeux.on 'subscribe' -> null
# bayeux.on 'unsubscribe' -> null
# bayeux.on 'disconnect' -> null
