@name = 'diskstats'
@description = 'Filesystems information'

u = require './utils'

# Linux 2.6.25 and above
fields = 'major minor name read_completed read_merged read_sectors read_ms write_completed write_merged write_sectors write_ms io_inprogress io_ms io_weighted_ms'.split /\s+/

@get = (cb) ->
  diskstats = {}

  content = u.content_of '/proc/diskstats'

  for line in content
    l = u.split_on_blanks line
    name = l[2]
    diskstats[name] = {}
    diskstats[name][key] = parseInt l[i] for key, i in fields

  cb null, diskstats
