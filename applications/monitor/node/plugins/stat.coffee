@name = 'stat'
@description = 'Kernel and System statistics'

u = require './utils'

cpu_fields = 'user nice system idle iowait irq softirq steal guest'.split /\s+/
diskio_fields = 'noinfo read_io read_blk write_io write_blk'.split /\s+/

@get = (cb) ->
  stat = {}

  content = u.content_of '/proc/stat'
  for line in content
    l = u.split_on_blanks line
    name = l.shift()
    stat[name] = {}

    if name.match /^cpu/
      stat[name][key] = parseInt l[i] for key, i in cpu_fields
    else if name is 'page' or name is 'swap'
      stat[name] =
        in: parseInt l[0]
        out: parseInt l[1]
    else if name is 'intr'
      stat[name].total = parseInt l.shift()
      stat[name].serviced = l.map parseInt
    else if name is 'disk_io'
      stat[name] = l.map (x) ->
        x = x.split /[(,:)]/
        a = {}
        a[key] = parseInt x[i] for key, i in diskio_fields
        return a
    else if l.length is 1
      stat[name] = u.value l[0]
    else
      stat[name] = l.map u.value

  cb stat
