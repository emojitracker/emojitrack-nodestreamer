cluster = require('cluster')
config  = require('./config')

class Monitor
  constructor: (@clients) ->
    # needs to be different redis client than subscribe/psubscribes
    @redisReportingClient = config.redis_connect()

    if config.ENV is 'staging' || config.ENV is 'production'
      setInterval @send_report, config.STREAM_STATUS_UPDATE_RATE

  workerName: ->
    return "" unless cluster.worker?
    "-worker.#{cluster.worker.id}"

  server_node_name: ->
    platform = 'node'
    environment = config.ENV
    dyno = process.env.DYNO || 'unknown'
    "#{platform}-#{environment}-#{dyno}#{@workerName()}"

  status_report: ->
    {
      node: @server_node_name()
      status: 'OK'
      reported_at: Math.floor(Date.now() / 1000)
      connections: @clients.status_hash()
    }

  send_report: =>
    @redisReportingClient.hset(
      config.STREAM_STATUS_REDIS_KEY,
      @server_node_name(),
      JSON.stringify( @status_report() )
    )

module.exports = Monitor
