_ = require('lodash')
uuid = require('node-uuid')
debug = require('debug')('emojitrack-sse:ConnectionPool')

class ConnectionPool
  constructor: () ->
    @_connections = {}

  add: (channel,req,res) ->
    id = uuid.v1()
    @_connections[id] = new Connection(channel,req,res)
    debug "subscribed client #{id} to #{channel}"
    id

  remove: (id) ->
    debug "unsubscribed client #{id}"
    delete @_connections[id]

  count: ->
    Object.keys(@_connections).length

  broadcast: ({data,event,channel}) ->
    client.sse_send(data,event) for client in @_match(channel)

  _match: (channel) ->
    _.where(@_connections,{channel:channel})

  status_hash: ->
    _.map @_connections, (conn)->conn.status_hash()

class Connection
  constructor: (@channel,@req,@res) ->
    @createdAt = Date.now()

  age: ->
    Math.floor( (Date.now() - @createdAt) / 1000 )

  sse_send: (data,event=null) ->
    @res.write @_sse_string(data,event)

  _sse_string: (data,event=null) ->
    "event:#{event}\ndata:#{data}\n\n" if event?
    "data:#{data}\n\n"

  # return a hash of what our reporting infrastructure expects
  status_hash: ->
    {
      request_path: @req.path
      tag: @channel.split('/')[2] || null
      created_at: @createdAt
      age: @age()
      client_ip: @req.ip
      client_user_agent: @req.get('User-Agent')
    }


module.exports = ConnectionPool
module.exports.Connection = Connection
