cluster = require('cluster')

################################################################################
#                      _
#  _ __ ___   __ _ ___| |_ ___ _ __
# | '_ ` _ \ / _` / __| __/ _ \ '__|
# | | | | | | (_| \__ \ ||  __/ |
# |_| |_| |_|\__,_|___/\__\___|_|
#
################################################################################

if cluster.isMaster
  config         = require('./lib/config')
  ScorePacker    = require('./lib/scorePacker')

  debug    = require('debug')('emojitrack-sse:clusterMaster')
  cpuCount = require('os').cpus().length
  numWorkers  = if cpuCount >= 2 then (cpuCount - 1) else 1
  cluster.fork() for [1..numWorkers]

  workerBroadcast = (msg) ->
    cluster.workers[id].send(msg) for id in Object.keys(cluster.workers)

  ###
  # redis event stuff
  ###
  redisStreamClient = config.redis_connect()
  scorepacker = new ScorePacker(17) #17ms

  redisStreamClient.subscribe('stream.score_updates')
  redisStreamClient.psubscribe('stream.tweet_updates.*')
  # redisStreamClient.psubscribe('stream.interaction.*')

  redisStreamClient.on 'message', (channel, msg) ->
    # in theory we could check the channel, but since we are only subscribed to one
    # let's not bother and save an unncessary comparison operation.  in future may be necessary.
    workerBroadcast {action: 'broadcast', payload: {data: msg, event: null, namespace: '/raw'}}
    scorepacker.increment(msg) #send to score packer for eps rollup stream

  redisStreamClient.on 'pmessage', (pattern, channel, msg) ->
    if pattern == 'stream.tweet_updates.*'
      id = channel.split('.')[2]
      workerBroadcast {
                        action: 'broadcast'
                        payload: {
                          data: msg
                          event: channel
                          namespace: "/details/#{id}"
                        }
                      }
    # else if pattern == 'stream.interaction.*'
    #TODO: reimplement me when we need kiosk mode again

  scorepacker.on 'expunge', (scores) ->
    workerBroadcast {action: 'broadcast', payload: {data: JSON.stringify(scores), event: null, namespace: '/eps'}}


################################################################################
#                     _
# __      _____  _ __| | _____ _ __
# \ \ /\ / / _ \| '__| |/ / _ \ '__|
#  \ V  V / (_) | |  |   <  __/ |
#   \_/\_/ \___/|_|  |_|\_\___|_|
#
################################################################################

if cluster.isWorker
  debug   = require('debug')("emojitrack-sse:worker:#{cluster.worker.id}")
  app     = require('express')()
  http    = require('http')
  server  = http.Server(app)

  config         = require('./lib/config')
  ConnectionPool = require('./lib/connectionPool')
  Monitor = require('./lib/monitor')

  ###
  # stand up services
  ###

  if config.ENV is 'staging' or config.ENV is 'production'
    # trust x forwarded for headers from proxy (heroku routing)
    app.enable('trust proxy')
    # enable new relic reporting
    require('newrelic')

  server.listen config.PORT, ->
    console.log("Worker #{cluster.worker.id} listening on " + config.PORT)

  ###
  # routing event stuff
  ###
  clients = new ConnectionPool()

  app.get '/subscribe/:namespace*', (req, res) ->
    namespace = '/' + req.params.namespace + req.params[0]
    clients.provision req,res,namespace

  ###
  # worker receive event stuff
  ###
  process.on 'message', (msg) ->
    switch msg.action
      when 'broadcast' then clients.broadcast msg.payload

  ###
  # monitoring
  ###
  monitor = new Monitor(clients)
  app.get '/admin/status.json', (req, res) ->
    res.json monitor.status_report()
