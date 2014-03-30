chai = require('chai')
chai.should()

ConnectionPool = require '../lib/connectionPool'

describe 'ConnectionPool', ->
  describe '#add()', ->
    before ->
      @cp = new ConnectionPool()
    it "should return a client UUID for future reference", ->
      id = @cp.add()
      /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.test(id).should.equal true

  describe '#count()', ->
    before -> @cp = new ConnectionPool
    it "should return proper counts after addition", ->
      @first  = @cp.add()
      @cp.count().should.equal 1
      @second = @cp.add()
      @cp.count().should.equal 2
    it "should return proper counts after a deletion", ->
      @cp.remove(@first)
      @cp.count().should.equal 1

  describe "#_match()", ->
    it "should find connections that match a specific channel", ->
      cp = new ConnectionPool
      cp.add(channel) for channel in ['aaa','bbb','ccc','aaa']
      cp.count().should.equal 4
      cp._match('aaa').should.be.a('array')
      cp._match('aaa').length.should.equal 2
      cp._match('bbb').length.should.equal 1

describe 'ConnectionPool.Connection', ->
    describe '#age()', ->
      it 'should have an age equal to the age of the object', (done) ->
        conn = new ConnectionPool.Connection
        setTimeout ->
          conn.age().should.be.above(1)
          conn.age().should.be.below(10)
          done()
        ,5
