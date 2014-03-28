chai = require('chai')
chai.should()

ScorePacker = require '../lib/scorePacker'

describe 'ScorePacker', ->
  describe ".new()", ->
    it 'should initialize cleanly', ->
      sc = new ScorePacker()
    it 'should take an optional period for how often to expunge', (done) ->
      sc = new ScorePacker(10)
      sc.on 'expunge', -> done()

  describe 'basic instance methods', ->

    describe '#increment()', ->
      it 'should create new values and return new score of the key', ->
        new ScorePacker().increment('foo').should.equal 1
      it 'should allow me to increment by arbitrary values', ->
        new ScorePacker().increment('bar',5).should.equal 5
      it 'should keep track of values for a given key as they increment', ->
        sc = new ScorePacker()
        sc.increment('cat').should.equal 1
        sc.increment('cat').should.equal 2
        sc.increment('cat').should.equal 3

    describe '#score()', ->
      it 'should return the score of a key', ->
        sc = new ScorePacker()
        sc.increment('foo')
        sc.score('foo').should.equal 1

    describe '#scores()', ->
      it 'should be an accessor for the underlying score value object', ->
        sc = new ScorePacker()
        sc.scores().should.equal sc._scores

    describe '#empty()', ->
      it 'should empty and return a reference to itself', ->
        sc = new ScorePacker()
        sc.increment('foo')
        sc.increment('bar')
        Object.keys(sc.empty()._scores).length.should.equal 0

    describe '#isEmpty()', ->
      it 'should know whether it is currently empty or not', ->
        sc = new ScorePacker()
        sc.isEmpty().should.equal true
        sc.increment('foo')
        sc.isEmpty().should.equal false

  describe 'handle periodic expunging', ->
    describe '#expunge()', ->
      it 'should emit score values to the expunged event', (done) ->
        sc = new ScorePacker()
        sc.on 'expunge', (payload) ->
          payload.should.equal sc._scores
          done()
        sc.expunge()
      it 'should reset itself after an expunge', ->
        sc = new ScorePacker()
        sc.increment('foo')
        sc.isEmpty().should.equal false
        sc.expunge()
        sc.isEmpty().should.equal true
