# emojitrack-nodestreamer

[![Build Status](https://travis-ci.org/mroth/emojitrack-nodestreamer.svg?branch=master)](https://travis-ci.org/mroth/emojitrack-nodestreamer)

First stab at experimental standalone replacement for emojitrack SSE streaming
web services, using node evented methods rather than MRI ruby with threads.
While the Ruby version was written in spaghetti-land while I had no idea what I
was doing, this version was written from scratch after understanding the problem
domain well. Thus, it's significantly better structured, has some unit tests,
and should be better code in general overall.

This should be API compatible with the MRI version. (In fact, we're load
balancing 50% of clients to each right now to test in production.)  For a full
explanation of the responsibilities of this system and it's API, see the README
for [mroth/emojitrack-streamer-spec](//github.com/mroth/emojitrack-streamer-spec).

The first stab at this was actually slower (albeit most consistent), so now
experimenting with cluster workers to try to take advantage of multiple CPU
cores to match ruby speed...

### Feature differences from Ruby version

 - No handling of downgraded connection-close if needed, requires a fully
   working routing environment (should be good only with [new routing layer](#) on
   Heroku and `labs:websockets` enabled)
 - No handling of interactive kiosk-mode streams, left out for now for time
   savings since they aren't in active use until we have another emojitracker
   physical installation.
 - No implementation of logging to graphite yet (again, waiting until we know
   we want to use this as the primary streamer in production.)

### Discussion

 - The first stab at this is in `server-sse.coffee`.  
 - There is a revised multi-process version in `server-cluster.coffee`.  
   It attempts to distribute the load of clients across `numCpus-1` forked
   processes, while preserving a core for the master process to handle reading
   from Redis and doing the ScorePacker rollup messages.

It's unclear why this isn't more significantly faster than the naive MRI
implementation. This is almost pure IO and event handling, which NodeJS should
excel at.  There is some low hanging fruit in terms of redundant String
operations, but nothing that should account for much CPU usage (and fixing those
things proved to show no real difference in benchmarking, so I left them out to
try to find the real critical paths.)

Benchmarks coming soon.

### TODO:

 - [x] logging
 - [x] admin interface reporting
 - [x] add newrelic reporting
 - [ ] performance profiling vs ruby threads solution
 - [ ] legacy graphite reporting?
