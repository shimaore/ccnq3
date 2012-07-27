@name = 'interrupts'
@description = 'System interrupts'

u = require './utils'

@get = (cb) ->
  interrupts = {}

  content = u.content_of '/proc/interrupts'
  cpus = u.split_on_blanks content.shift()

  for line in content
    l = u.split_on_blanks line
    name = l.shift().replace /:$/, ''
    interrupts[name] =
      name: name
      cpus: {}
    for cpu in cpus
      interrupts[name].cpus[cpu] = parseInt l.shift()
    interrupts[name].description = l.join ' '

  cb interrupts
