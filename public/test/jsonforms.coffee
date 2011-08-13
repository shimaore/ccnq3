#  Copyright (c) 2010 Stephane Alnet
#  Released under the Affero GPL3 license or above.

module.exports =
  get_json_value: (data,name) ->

    # We can't resolve anything on an empty object.
    if not data?
      return data

    if not name? or name is ''
      return data

    if match = name.match /^\[(\d+)\](.*)$/
      [_i,part,rest] = match
      index = parseInt(part)-1
      return arguments.callee data[index], rest

    if match = name.match /^\.?(\w+)(.*)$/
      [_i,part,rest] = match
      return arguments.callee data[part], rest

    throw "Could not parse name #{name}"

  change_json_value: (data,name,value) ->

    if not name? or name is ''
      data = value
      return data

    if match = name.match /^\[(\d+)\](.*)$/
      [_i,part,rest] = match
      data ?= []
      index = parseInt(part)-1
      data[index] = arguments.callee data[index], rest, value
      return data

    if match = name.match /^\.?(\w+)(.*)$/
      [_i,part,rest] = match
      data ?= {}
      data[part] = arguments.callee data[part], rest, value
      return data

    throw "Could not parse name #{name}"
