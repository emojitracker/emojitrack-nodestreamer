First stab at experimental standalone replacement for emojitrack streaming
web services, using node evented methods rather than MRI ruby with threads.

TODO:
 - logging
 - admin interface reporting
 - graphite reporting
 - switch to primus.io/primus + primus-multiplex
 - performance profiling vs ruby threads solution
 - performance profiling different primus backends
 - look into possibly using jsonh/msgpack
 - add newrelic reporting

Even if this is just equivalent in performance, separating it out into its own
service will let me scale it independently of the normal web API calls.
