@name = 'meminfo'
@description = 'Memory information'

u = require './utils'

@get = (cb) ->
  meminfo = {}

  content = u.content_of '/proc/meminfo'
  for line in content
    l = u.split_on_blanks line
    name = l[0].replace /:$/, ''
    meminfo[name] =
      value: parseInt l[1]
      units: l[2]

  cb null, meminfo
