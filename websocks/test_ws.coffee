WebSocket = require('ws')
ws = new WebSocket('ws://localhost:8080/fart')

# ws.on 'open', function() {
#     ws.send('something');
# });
ws.on 'message', (data, flags) ->
  #flags.binary will be set if a binary data is received
  #flags.masked will be set if the data was masked
  console.log data
