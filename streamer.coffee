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

redis   = require("redis")
url     = require("url")
app     = require('express')()
server  = require('http').Server(app)
io      = require('socket.io')(server)
io.set('log level', 3) #this seems to do nothing in socket.io 1.0 sigh

ScorePacker = require('./lib/ScorePacker')

###
# stand up services
###

port = process.env.PORT || 8000
server.listen port, ->
  console.log('Listening on ' + port)


sc = new ScoreCache(17) #1000/60 rounded
sc.on 'expunge', (scores) ->
  io.of('/eps').emit 'bulk_score_update', JSON.stringify( scores )

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

redisStreamClient.on 'pmessage', (pattern, channel, msg) ->
  if channel == 'stream.score_updates'
    io.of('/raw').emit 'score_update', msg #TODO: maybe disable now that we dont use?
    sc.increment msg
  else if channel.indexOf('stream.tweet_updates.') == 0 #.startsWith
    channelID = channel.split('.')[2]
    io.of("/details/#{channelID}").emit 'tweet', msg
  # else if 'stream.interaction.*'


###
# routing event stuff
###

# huh, this might actually all be handled with subscribe messages now on the client side...
raw = io.of('/raw').on 'connection', ->
  console.log "connection to raw"

raw = io.of('/details').on 'connection', ->
  console.log "connection to details"

raw = io.on 'connection', ->
  console.log "generic connection"
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
