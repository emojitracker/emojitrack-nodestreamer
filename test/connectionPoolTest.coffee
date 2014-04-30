chai = require('chai')
chai.should()

ConnectionPool = require '../lib/connectionPool'

describe 'ConnectionPool', ->
  describe '#_add()', ->
    before ->
      @cp = new ConnectionPool()
    it "should return a client UUID for future reference", ->
      id = @cp._add()
      /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/.test(id).should.equal true

  describe '#count()', ->
    before -> @cp = new ConnectionPool
    it "should return proper counts after addition", ->
      @first  = @cp._add()
      @cp.count().should.equal 1
      @second = @cp._add()
      @cp.count().should.equal 2
    it "should return proper counts after a deletion", ->
      @cp._remove(@first)
      @cp.count().should.equal 1

  describe "#_match()", ->
    it "should find connections that match a specific channel", ->
      cp = new ConnectionPool
      cp._add(channel) for channel in ['aaa','bbb','ccc','aaa']
      cp.count().should.equal 4
      cp._match('aaa').should.be.a('array')
      cp._match('aaa').length.should.equal 2
      cp._match('bbb').length.should.equal 1

describe 'ConnectionPool.Connection', ->
  it "should probably have tests someday"
