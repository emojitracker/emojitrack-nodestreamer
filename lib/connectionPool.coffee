cluster = require('cluster')
uuid = require('node-uuid')
_ = require('lodash')
config = require('./config')
debug = require('debug')('emojitrack-sse:ConnectionPool')

class ConnectionPool
  constructor: () ->
    @_connections = {}

  provision: (req,res,namespace) ->
    # do the SSE preamble stuff as soon as connection obj is created
    res.writeHead(200, {
      'Access-Control-Allow-Origin' : '*',
      'Content-Type'                : 'text/event-stream; charset=utf-8',
      'Cache-Control'               : 'no-cache',
      'Connection'                  : 'keep-alive'
      'Transfer-Encoding'           : 'identity'
    })
    if req.method is 'HEAD'
      # if we get a HTTP HEAD, we are supposed to return the headers exactly
      # like a normal GET, but no body.  So on this case, we'll need to close
      # the connection immediately at this point without writing anything.
      # - http://www.giantflyingsaucer.com/blog/?p=3936
      console.log "HEAD:\t#{req.path}\tby #{req.ip}" if config.VERBOSE
      res.end ''
    else
      #
      # normal case is a GET, and we set up our normal connection pool handling
      #
      console.log "CONNECT:\t#{req.path}\tby #{req.ip}" if config.VERBOSE
      req.socket.setTimeout(Infinity) #TODO: move me to client?
      res.write('\n')

      id = @add(namespace,req,res)

      req.on 'close', =>
        @remove(id)
        console.log "DISCONNECT:\t#{req.path}\tby #{req.ip}" if config.VERBOSE


  add: (namespace,req,res) ->
    id = uuid.v1()
    conn = new Connection(namespace,req,res)
    @_connections[id] = conn
    debug "subscribed client #{id} to #{namespace}"
    id

  remove: (id) ->
    debug "unsubscribed client #{id}"
    delete @_connections[id]

  count: ->
    Object.keys(@_connections).length

  broadcast: ({data,event,namespace}) ->
    client.sse_send(data,event) for client in @_match(namespace)

  _match: (namespace) ->
    _.where(@_connections,{namespace:namespace})

  status_hash: ->
    _.map @_connections, (conn)->conn.status_hash()


class Connection
  constructor: (@namespace,@req,@res) ->
    @createdAt = Date.now()

  sse_send: (data,event=null) ->
    @res.write @_sse_string(data,event)

  _sse_string: (data,event=null) ->
    return "event:#{event}\ndata:#{data}\n\n" if event?
    "data:#{data}\n\n"

  # return a hash of what our reporting infrastructure expects
  status_hash: ->
    {
      request_path: @req.path
      namespace: @namespace
      created_at: Math.floor( @createdAt / 1000 )
      client_ip: @req.ip
      user_agent: @req.get('User-Agent')
    }


module.exports = ConnectionPool
module.exports.Connection = Connection
