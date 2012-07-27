os = require 'os'
fs = require 'fs'

@split_on_blanks = (t) ->
  t.split(/\s+/).filter (x) -> x isnt ''

@content_of = (name) ->
  content = fs.readFileSync(name,'utf8').split os.EOL ? /\n/
  content.pop()
  return content

@value = (x) ->
  n = parseInt x
  if isNaN n then x else n
