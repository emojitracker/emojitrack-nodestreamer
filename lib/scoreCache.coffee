# Rollup a score cache
# Expunges every N period

class ScoreCache

  # Public: construct a new ScoreCache
  #
  # period           - how often you want scores expunged (optional)
  # expungeScoreSink - the Function that scores will be passed
  #                    to before they are expunged (optional)
  #
  constructor: (@period=null, @expungeScoreSink) ->
    @_scores = {}

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


module.exports = ScoreCache
