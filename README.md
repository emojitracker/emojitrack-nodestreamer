# emojitrack-nodestreamer

First stab at experimental standalone replacement for emojitrack SSE streaming
web services, using node evented methods rather than MRI ruby with threads.

the first stab at this was actually slower, so now experimenting with cluster
workers to try to take advantage of multiple CPU cores to match ruby speed.

### Differences with ruby version
description

### TODO:

 - [x] logging
 - [x] admin interface reporting
 - [ ] graphite reporting?
 - [ ] performance profiling vs ruby threads solution
 - [ ] look into possibly using jsonh/msgpack
 - [x] add newrelic reporting

some boilerplate for API documentation below...
