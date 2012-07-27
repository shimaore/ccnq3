
####
#
# 1. get config
# 2. retrieve data
# 3. push into db
# 4. restart after interval ## setInterval(cb,ms)
#
#

plugins = ['os','process','processes','interrupts','diskstats','meminfo','netdev','stat','vmstat']

get_data = (cb) ->

  get_data_of = (n,data,cb) ->
    if n >= plugins.length
      return cb data

    plugin = plugins[n]
    p = require "./plugins/#{plugin}"
    console.log "Running #{plugin}"

    p.get (error,rec) ->
      if error?
        data.errors ?= {}
        data.errors[p.name] = error
      data[plugin] = rec if rec?

      get_data_of n+1, data, cb

  # FIXME: /proc/stat
  # etc., see http://www.kernel.org/doc/man-pages/online/pages/man5/proc.5.html

  get_data_of 0, {}, cb

get_data (data) ->
  console.log "data = " + JSON.stringify data, null, "  "
