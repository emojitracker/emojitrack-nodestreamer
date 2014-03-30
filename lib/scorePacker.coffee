# Rolls up a score value for given keys.
# Expunges those scores as an event every N period ms.
# Used to 'summarize' extremely high volume data streams,
# and consume them at a predictable rate.
#
# Does not expunge when cache is empty, so do not rely upon for timing data.
debug = require('debug')('emojitrack-sse:ScorePacker')

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

  count: ->
    Object.keys(@_scores).length

  empty: () ->
    @_scores = {}
    this

  isEmpty: () ->
    @count() == 0

  expunge: () =>
    if @isEmpty()
      debug "expunge: timer interval reached but cache is empty"
    else
      debug "expunge: #{@count()} values emitted"
      @emit 'expunge', @_scores
      @empty()


module.exports = ScorePacker
