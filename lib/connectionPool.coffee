_ = require('underscore')
uuid = require('node-uuid')
debug = require('debug')('emojitrack:ConnectionPool')

class ConnectionPool
  constructor: () ->
    @_connections = {}

  add: (channel,req,res) ->
    id = uuid.v1()
    @_connections[id] = new Connection(channel,req,res)
    debug "subscribed client #{id} (#{req.ip}) to #{channel}"
    id

  remove: (id) ->
    debug "unsubscribed client #{id}"
    delete @_connections[id]

  count: ->
    Object.keys(@_connections).length

  broadcast: ({data,event,namespace}) ->#(data,event=null,channel=null) ->
    #TODO replace with emit so it doesnt block? or does it block??
    debug "got broadcast msg #{data}"

    if channel? #restrict msg to only matching a specific channel
      for conn in @_connections
        conn.send(data,event) if client.channel == namespace
    else
      conn.send(data,event) for conn in @_connections

  _match: (channel) ->
    _.where(@_connections,{channel:channel})

  status_hash: ->
    _.pluck(@_connections,'status_hash')

class Connection
  constructor: (@channel,@req,@res) ->
    @createdAt = Date.now()

  age: ->
    Date.now() - @createdAt

  sse_send: (data,event=null) ->
    @res.write _sse_string(data,event)

  _sse_string: (data,event=null) ->
    "event:#{event}\ndata:#{data}\n\n" if event?
    "data:#{data}\n\n"

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
