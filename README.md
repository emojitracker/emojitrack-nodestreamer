First stab at experimental standalone replacement for emojitrack streaming
web services, using node evented methods rather than MRI ruby with threads.

TODO:
 - logging
 - admin interface reporting
 - graphite reporting
 - performance profiling vs ruby threads solution

Even if this is just equivalent in performance, separating it out into its own
service will let me scale it independently of the normal web API calls.
