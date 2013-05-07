output_dir = './_site'
fs = require 'fs'
markdown = require 'marked'
coffeecup = require 'coffeecup'
css = (o) -> require('ccss').compile o
coffeescript = require 'coffee-script'
docco = require 'docco'

task 'docs', 'Rebuild the documentation', ->

  layout = coffeecup.compile fs.readFileSync './_layouts/layout.coffee', 'utf8'

  docs =
    index: './doc/index.md'
    install: './doc/Install.md'
    upgrade: './doc/upgrade.md'
    provisioning: './doc/Provisioning.md'
    specs: './doc/data-dictionary.md'

  make_name = (t) ->
    t = t.trim().toLowerCase()
    t = t.replace /[ ]/g, "-"
    t.replace /[^a-z0-9]/g, ''
  make_title = (t) ->
    t.trim().replace /[\[\]\(\)]/g, '-'

  for dest, file of docs
    console.log "** #{file} -> #{dest}"
    toc = []
    src = fs.readFileSync file, 'utf8'
    src = src.replace /^(.+)[ \t]*\n=+[ \t]*\n+|^(.+)[ \t]*\n-+[ \t]*\n+|^(\#{1,6})[ \t]*(.+?)[ \t]*\#*\n+/gm, (whole,m1,m2,m3,m4) ->
      if m1?
        name = make_name m1
        title = make_title m1
        toc.push name:name, title:title, level:1
        return """<a name="#{name}"></a>\n#{m1}\n====\n"""
      if m2?
        name = make_name m2
        title = make_title m2
        toc.push name:name, title:title, level:2
        return """<a name="#{name}"/></a>\n#{m2}\n----\n"""
      if m3?
        name = make_name m4
        title = make_title m4
        toc.push name:name, title:title, level:m3.length
        return """<a name="#{name}"/></a>\n#{m3} #{m4}\n"""

    toc = toc.map (x) ->
      spaces = '                '.substr 2, x.level*2
      "#{spaces}* [#{x.title}](##{x.name})\n"

    src = "\n" + toc.join('') + "\n" + src

    body = markdown.parse src
    fs.writeFileSync "./#{output_dir}/#{dest}.html",
      layout
        title: dest
        body: body
        style: css require('./_layouts/default.css').css

spawn = require('child_process').spawn
run = (args...,cb) ->
  if typeof cb isnt 'function'
    args.push cb
    cb = null
  command = args.shift()
  console.log '** ', command, args.join ' '
  cmd = spawn command, args,
    stdio: ['ignore',process.stdout,process.stderr]
  if cb?
    cmd.on 'exit', cb
