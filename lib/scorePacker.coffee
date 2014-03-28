# Rolls up a score value for given keys.
# Expunges those scores as an event every N period ms.
# Used to 'summarize' extremely high volume data streams,
# and consume them at a predictable rate.

{EventEmitter} = require 'events'
class ScorePacker extends EventEmitter

  # Public: construct a new ScorePacker
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
    @emit 'expunge', @_scores
    @empty()


module.exports = ScorePacker
