# Rollup a score cache
# Expunges every N period
{EventEmitter} = require 'events'
class ScoreCache extends EventEmitter

  # Public: construct a new ScoreCache
  #
  # period - how often you want scores expunged (optional).
  #
  constructor: (period=null) ->
    @_scores = {}

    if period?
      setInterval @expunge, period

  increment: (key, amount=1) ->
    @_scores[key] ?= 0
    @_scores[key] += amount

  score: (key) ->
    @_scores[key]

  scores: () ->
    @_scores

  empty: () ->
    @_scores = {}
    this

  isEmpty: () ->
    Object.keys(@_scores).length == 0

  expunge: () =>
    @emit 'expunge'
    @empty()


module.exports = ScoreCache
