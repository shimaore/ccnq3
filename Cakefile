output_dir = './_site'
fs = require 'fs'
markdown = require 'markdown'
coffeecup = require 'coffeecup'
coffeescript = require 'coffee-script'
docco = require 'docco'

task 'docs', 'Rebuild the documentation', ->
  docco.document ['./public/js/ccnq3.coffee'], output: output_dir

  layout = coffeecup.compile fs.readFileSync './_layouts/layout.coffee', 'utf8'

  docs =
    index: './doc/doc/index.mdwn'
    install: './doc/doc/Install.mdwn'
    provisioning: './doc/doc/Provisioning.mdwn'
    specs: './doc/doc/data-dictionary.mdwn'

  for dest, file of docs
    console.log "** #{file} -> #{dest}"
    fs.writeFileSync "./#{output_dir}/#{dest}.html",
      layout
        title: dest
        body: markdown.markdown.toHTML fs.readFileSync file, 'utf8'
        stylesheet: 'docco'

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
