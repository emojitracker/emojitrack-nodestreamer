# Rolls up a score value for given keys.
# Expunges those scores as an event every period N milliseconds.
#
# Used to 'summarize' extremely high volume data streams, and consume them at a
# predictable rate.
#
# Note: does not expunge when cache is empty, so do not rely upon the rate for
# timing data.

debug  = require('debug')('emojitrack-sse:ScorePacker')
events = require 'events'

class ScorePacker extends events.EventEmitter

  constructor: (period=null) ->
    @_scores = {}
    if period?
      setInterval @expunge, period

  # increment score for given key by value
  increment: (key, amount=1) ->
    @_scores[key] ?= 0
    @_scores[key] += amount

  # score for a given key
  score: (key) ->
    @_scores[key]

  # accessor to internal score cache object
  scores: () ->
    @_scores

  # count of keys in score cache
  count: ->
    Object.keys(@_scores).length

  # empties the score cache, effectively resets all scores to zero.
  empty: () ->
    @_scores = {}
    this

  # is the score cache currently empty?
  isEmpty: () ->
    @count() == 0

  # expunges the packed score summary as an event, then empties cache.
  expunge: () =>
    if @isEmpty()
      debug "expunge: cache is empty, no emit"
    else
      debug "expunge: #{@count()} values emitted"
      @emit 'expunge', @_scores
      @empty()


module.exports = ScorePacker
