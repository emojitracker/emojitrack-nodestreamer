http = require('http')
chai = require('chai')
chai.should()
expect = chai.expect

describe 'subscribe endpoints', ->

  describe 'HEAD /subscribe/eps', ->
    before (done)->
      # options = {method: 'HEAD', host: 'emojitrack-streamer-staging.herokuapp.com', port: 80, path: '/subscribe/eps'}
      options = {method: 'HEAD', host: 'localhost', port: 8001, path: '/subscribe/eps'}
      req = http.request options, (res) =>
        @res = res
        done()
      req.end()

    it 'should support HTTP HEAD requests and not hang'
    it 'should send status code 200', ->
      @res.statusCode.should.equal 200
    it 'should set Content-Type: text/event-stream;charset=utf-8', ->
      expect(@res.headers['content-type']).to.equal 'text/event-stream;charset=utf-8'
    it 'should set Cache-Control: no-cache', ->
      expect(@res.headers['cache-control']).to.equal 'no-cache'
    it 'should set a proper keep-alive header', ->
      expect(@res.headers['connection']).to.equal 'keep-alive'
    it 'should set proper CORS headers', ->
      expect(@res.headers['access-control-allow-origin']).to.equal '*'


  describe 'GET /subscribe/eps', ->
    it 'should send data'
