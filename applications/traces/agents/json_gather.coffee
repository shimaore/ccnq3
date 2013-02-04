# json_gather.coffee
# (c) 2012 Stephane Alnet

module.exports = (self,cb) ->

  res = []

  self.on 'data', (data) ->
    res.push data

  self.on 'end', ->
    cb res

  return
