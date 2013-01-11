# json_pipe.coffee
# (c) 2012 Stephane Alnet

module.exports = (self,res) ->

  first_entry = true

  self.on 'data', (data) ->
    # Make the array properly formatted
    res.write if first_entry then '[' else ','
    first_entry = false
    # Write the JSON content
    res.write JSON.stringify(data)

  self.on 'end', ->
    # Close the JSON content
    res.write if first_entry then '[]' else ']'
    res.end()

# Self-test
do ->
  events = require 'events'
  assert = require 'assert'
  self = new events.EventEmitter
  buffer = ''
  res =
    write: (data) -> buffer += data
    end: ->
      assert.equal buffer, '[{"foo":"bar"},{"bar":"bar"}]'
  module.exports self, res
  self.emit 'data', foo:'bar'
  self.emit 'data', bar:'bar'
  self.emit 'end'
