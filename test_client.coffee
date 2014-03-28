io = require('socket.io-client')

raw = io('http://localhost:5000/raw')
eps = io('http://localhost:5000/eps')
deetz = io('http://localhost:5000/details/1F44C')

# raw.on 'connect', ->
#   raw.on 'score_update', (details) ->
#     console.log details

eps.on 'connect', ->
  eps.on 'bulk_score_update', (details) ->
    console.log details

deetz.on 'connect', ->
  deetz.on 'tweet', (details) ->
    console.log details
