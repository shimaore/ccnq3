@name = 'processes'
@description = 'Provide information about notable running processes'

# TODO Use /proc/[pid]/task/[tid]/* to provide thread-level data.

fs = require 'fs'
u = require './utils'

stat_fields = 'pid comm state ppid pgrp session tty tpgid flags minflt cminflt majflt cmajflt utime stime cutime cstime priority nice num_threads itrealvalue starttime vsize rss rsslim startcode endcode startstack kstkesp kstkeip signal blocked sigignore sigcatch wchan nswap cnswap exit_signal processor rt_priority policy delayacct_blkio_ticks guest_time cguest_time'.split /\s+/
statm_fields = 'size resident share text lib data dirty'.split /\s+/

@get = (cb) ->
  processes = {}
  for p in fs.readdirSync('/proc') when p.match /^\d/
    do (p) ->

      # Utilities
      get = (n) ->
        try
          fs.readFileSync("/proc/#{p}/#{n}", 'utf8').replace /\n$/, ''

      get_cmdline = (n) ->
        cmdline = get(n).split /\u0000/
        cmdline.pop() # Last one is always ""
        return cmdline
      get_line = (n,f) ->
        l = get(n).split /\s+/
        r = {}
        r[key] = l[i] 
        for key, i in f
          v = parseInt l[i]
          r[key] = u.value l[i]
        return r

      # Build data record.
      processes[p] =
        comm: get 'comm'
        cmdline: get_cmdline 'cmdline'
        oom_score: parseInt get 'oom_score'
        stat: get_line 'stat', stat_fields
        statm: get_line 'statm', statm_fields

  cb null, processes
