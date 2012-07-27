@name = 'vmstat'
@description = 'Virtual Memory statistics'

u = require './utils'

@get = (cb) ->
  vmstat = {}

  content = u.content_of '/proc/vmstat'
  for line in content
    l = u.split_on_blanks line
    name = l[0]
    vmstat[name] = parseInt l[1]

  cb vmstat
