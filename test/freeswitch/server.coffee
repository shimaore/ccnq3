FS = require 'esl'
Q = require 'q'
log = -> console.log arguments...

delay = ->
  Q.delay 300
  @

server = FS.server (call) ->
  sequence = []
  for i in [0..1000]
    do (i) ->
      sequence.push delay
      sequence.push -> @command 'phrase', "say-number,#{i}"
      # sequence.push delay
      # sequence.push -> @command 'phrase', "say-counted,#{i}"

  outcome = call.sequence sequence

server.listen 7000
