# Also see http://visionmedia.github.com/expresso/

jf = require './jsonforms'
assert = require 'assert'
util = require 'util'

e =
  a: 3
  b: 4
  c:
    d: 5
    e: 6
    f: [ 7, 8, 9 ]
  g: [ 10, {
    h: 11
    i: 12
  }]

get_json_value    = (n) -> jf.get_json_value(e,n)
change_json_value = (n,v) -> jf.change_json_value(e,n,v)

module.exports =
  'test single': ->
    assert.equal  3, get_json_value 'a'
  'test double': ->
    assert.equal  5, get_json_value 'c.d'
  'test array': ->
    assert.equal  8, get_json_value 'c.f[2]'
  'test array hash': ->
    assert.equal 11, get_json_value 'g[2].h'

  'test change single': ->
    data = change_json_value 'a', 'foo'
    assert.equal  'foo', jf.get_json_value data, 'a'
  'test set single': ->
    data = change_json_value 'z', 'foo'
    assert.equal  'foo', jf.get_json_value data, 'z'
  'test change double': ->
    data = change_json_value 'c.e', 'foo'
    assert.equal  'foo', jf.get_json_value data, 'c.e'
  'test set double': ->
    data = change_json_value 'x.y', 'foo'
    assert.equal  'foo', jf.get_json_value data, 'x.y'
  'test change array': ->
    data = change_json_value 'f[3]', 'foo'
    assert.equal  'foo', jf.get_json_value data, 'f[3]'
  'test append array': ->
    data = change_json_value 'f[4]', 'foo'
    assert.equal  'foo', jf.get_json_value data, 'f[4]'
  'test set array': ->
    data = change_json_value 't[2]', 'foo'
    assert.equal  'foo', jf.get_json_value data, 't[2]'
