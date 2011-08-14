###
Deserialize and update a Javascript record into an HTML form.
Copyright (c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above.
###

($) ->

  get_json_value = (data,name) ->

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

  change_json_value = (data,name,value) ->

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


  # Fills in the form with the data in the record.
  $.fn.form_from_json = (data) ->
    # "this" refers to the jQuery object
    @find('input,textarea,select').each ->
      # "this" refers to the DOM element
      return if @type and (@type is 'reset' or @type is 'submit')
      # Do not deserialize the "_method" field (use by overrideMethod)
      return if @name and @name is '_method'

      if @name and data[@name]
        return $(@).val get_json_value data, @name

      if @id   and data[@id]
        return $(@).val get_json_value data, @id

      $(@).val('')

    return @

  # Fills in the form with the data in the record.
  $.fn.form_update_json = (data) ->
    # "this" refers to the jQuery object
    @find('input,textarea,select').each ->
      # "this" refers to the DOM element
      return if @type and (@type is 'reset' or @type is 'submit')
      # Do not deserialize the "_method" field (use by overrideMethod)
      return if @name and @name is '_method'

      if @name and data[@name]
        return change_json_value data, @name, $(@).val()

      if @id   and data[@id]
        return change_json_value data, @id,   $(@).val()

    return @



(jQuery)
