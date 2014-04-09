redis  = require('redis')
url    = require('url')
dotenv = require('dotenv').load()

to_bool =  (s) -> s and !!s.match(/^(true|t|yes|y|1)$/i)

module.exports = {

  VERBOSE: to_bool(process.env.VERBOSE) || false

  PORT: process.env.PORT || 8000
  REDIS_URL: process.env.REDIS_URL || 'http://localhost:6379'
  ENVIRONMENT: process.env.NODE_ENV || 'development'

  STREAM_STATUS_REDIS_KEY: 'admin_stream_status'
  STREAM_STATUS_UPDATE_RATE: 5000

  redis_connect: ->
    rtg = url.parse(@REDIS_URL)
    rclient = redis.createClient(rtg.port, rtg.hostname)
    rclient.auth(rtg.auth.split(":")[1])
    rclient

}
