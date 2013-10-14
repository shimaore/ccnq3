FS = require 'esl'
Q = require 'q'
log = -> console.log arguments...

delay = ->
  Q.delay 100
  @

server = FS.server (call) ->
  sequence = [
    delay
    -> @command 'answer'
    -> @command 'set', "language=en"
  ]
  for i in [0..1000]
    sequence.push delay
    sequence.push -> @command 'phrase', "say,#{i}"
    sequence.push -> @command 'phrase', "say,#{i} iterated"
    sequence.push -> @command 'phrase', "say,#{i} counted"

  outcome = call.sequence sequence

server.listen 7000
