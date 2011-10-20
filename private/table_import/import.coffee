#!/usr/bin/env coffee

line_oriented = (stream,callback) ->
  stream.setEncoding 'utf8' # Always
  buffer = ''
  stream.on 'data', (data) ->
    buffer += data
    lines = buffer.split "\n"
    buffer = lines.pop()
    lines.forEach callback

  stream.on 'end', ->
    callback(buffer)

request = require 'request'
util = require 'util'

push_docs = (uri,docs) ->

  request.post({uri:uri, json:{docs:docs}}).pipe(process.stdout)
###
(error, response, body) ->
    if not error and response.statusCode is 200
      console.log body
    else
      console.error """
        error: error
        statusCode: #{response.statusCode}
        body: #{util .inspect body}
      """
###

###
  Command-line
###

url = require 'url'

base_uri = process.argv[2]
bulk_uri = base_uri + '/_bulk_docs'

console.info "Pushing to #{bulk_uri}"

### 

Fields:

  initial_duration
  increment_duration
  count_cost
  duration_rate

###

docs = []

process.stdin.resume()
line_oriented process.stdin, (t) ->
  [prefix,description,count_cost,duration_rate] = t.split ';'
  return unless prefix.match /^\d+$/
  lines++
  doc =
    _id: prefix
    prefix: prefix
    description: description or prefix
    initial_duration: 0
    increment_duration: 60
    count_cost: count_cost
    duration_rate: duration_rate
  docs.push doc
  if docs.length is 500
    push_docs(bulk_uri,docs)
    lines = 0
    docs = []

if docs.length
  push_docs(bulk_uri,docs)

