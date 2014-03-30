Primus = require('primus')
multiplex = require('primus-multiplex')
http = require('http')
server = http.createServer()

primus = new Primus(server, { parser: 'JSON' });
primus.use('multiplex', multiplex)

Socket = primus.Socket
socket = new Socket('ws://localhost:8080')

eps   = socket.channel('eps') #io('http://localhost:5000/eps')
deetz = socket.channel('details/1F44C') #io('http://localhost:5000/details/1F44C')

# raw.on 'connect', ->
#   raw.on 'score_update', (details) ->
#     console.log details

eps.on 'data', (msg) ->
  console.log msg

deetz.on 'data', (msg) ->
  console.log msg

# eps.on 'connect', ->
#   eps.on 'bulk_score_update', (details) ->
#     console.log details
#
# deetz.on 'connect', ->
#   deetz.on 'tweet', (details) ->
#     console.log details
