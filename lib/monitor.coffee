config = require('./config')

class Monitor
  constructor: (@rawClients,@epsClients,@detailClients) ->
    # needs to be different redis client than subscribe/psubscribes
    @redisReportingClient = config.redis_connect()

    setInterval @send_report, config.STREAM_STATUS_UPDATE_RATE
    #TODO: only send the above on staging or prod

  server_node_name: ->
    platform = 'node'
    environment = config.ENVIRONMENT
    dyno = process.env.DYNO || 'unknown'
    "#{platform}-#{environment}-#{dyno}"

  status_report: ->
    {
      node: @server_node_name()
      reported_at: Date.now()
      connections: {
        stream_raw: @rawClients.status_hash()
        stream_eps: @epsClients.status_hash()
        stream_detail: @detailClients.status_hash()
      }
    }

  send_report: =>
    @redisReportingClient.hset(
      config.STREAM_STATUS_REDIS_KEY,
      @server_node_name(),
      JSON.stringify( @status_report() )
    )

module.exports = Monitor
