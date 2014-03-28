chai = require('chai')
chai.should()

ScoreCache = require '../lib/scoreCache'

describe 'ScoreCache', ->
  describe ".new()", ->
    it 'should initialize cleanly', ->
      sc = new ScoreCache()
    it 'should take an optional period for how often it should expunge'

  describe 'basic instance methods', ->

    describe '#increment()', ->
      it 'should create new values and return new score of the key', ->
        new ScoreCache().increment('foo').should.equal 1
      it 'should allow me to increment by arbitrary values', ->
        new ScoreCache().increment('bar',5).should.equal 5
      it 'should keep track of values for a given key as they increment', ->
        sc = new ScoreCache()
        sc.increment('cat').should.equal 1
        sc.increment('cat').should.equal 2
        sc.increment('cat').should.equal 3

    describe '#score()', ->
      it 'should return the score of a key', ->
        sc = new ScoreCache()
        sc.increment('foo')
        sc.score('foo').should.equal 1

    describe '#scores()', ->
      it 'should be an accessor for the underlying score value object', ->
        sc = new ScoreCache()
        sc.scores().should.equal sc._scores

    describe '#empty()', ->
      it 'should empty and return a reference to itself', ->
        sc = new ScoreCache()
        sc.increment('foo')
        sc.increment('bar')
        Object.keys(sc.empty()._scores).length.should.equal 0

    describe '#isEmpty()', ->
      it 'should know whether it is currently empty or not', ->
        sc = new ScoreCache()
        sc.isEmpty().should.equal true
        sc.increment('foo')
        sc.isEmpty().should.equal false

  describe 'handle periodic expunging', ->
    describe '#expunge()', ->
      it 'should emit values to the expunged event'
      it 'should reset itself after an expunge', ->
        sc = new ScoreCache()
        sc.increment('foo')
        sc.isEmpty().should.equal false
        sc.expunge()
        sc.isEmpty().should.equal true
