First stab at experimental standalone replacement for emojitrack SSE streaming
web services, using node evented methods rather than MRI ruby with threads.

TODO:
 - logging √
 - admin interface reporting √
 - graphite reporting
 - performance profiling vs ruby threads solution
 - look into possibly using jsonh/msgpack
 - add newrelic reporting √

x

some boilerplate for API documentation below...

** API text
/subscribe/eps
will emit a JSON blob every 17ms (1/60th of a second) containing the unicode IDs
that have incremented and the amount they have incremented.

Example:
  {'1F4C2':2,'2665':3,'2664':1,'1F65C':1}

If there have been no updates in that period, rather than a blank array, no message will be sent.  Therefore, do not rely on this for timing data.

msgpack version of that would be:
  [ [1F4C2,2],[2665,3],[2664,1],[1F65C,1]  ]
