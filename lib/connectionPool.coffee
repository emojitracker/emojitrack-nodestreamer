uuid = require('node-uuid')
_ = require('underscore')

class ConnectionPool
  constructor: () ->
    @_connections = {}

  add: (channel,req,res) ->
    id = uuid.v1()
    @_connections[id] = new Connection(channel,req,res)
    id

  remove: (id) ->
    delete @_connections[id]

  count: ->
    Object.keys(@_connections).length

  broadcast: (channel,data,event=null) ->
    #TODO replace with emit so it doesnt block? or does it block??
    for client in @_connections
      client.res.write( _sse_string(data,event) ) if client.channel == channel

  _match: (channel) ->
    _.where(@_connections,{channel:channel})

  _sse_string: (data,event=null) ->
    "event:#{event}\ndata:#{data}\n\n" if event?
    "data:#{data}\n\n"

  status_hash: ->
    {
      node: null
      reported_at: Date.now()
      connections: {
        stream_raw: null
        stream_eps: null
        stream_detail: null
      }
    }

class Connection
  constructor: (@channel,@req,@res) ->
    @createdAt = Date.now()

  age: ->
    Date.now() - @createdAt

  # return a hash of what our reporting infrastructure expects
  status_hash: ->
    {
      request_path: @req.path
      tag: @channel.split('/')[2]
      created_at: @created_at
      age: @age()
      client_ip: @req.ip
      client_user_agent: @req.get('User-Agent')
    }


module.exports = ConnectionPool
module.exports.Connection = Connection
