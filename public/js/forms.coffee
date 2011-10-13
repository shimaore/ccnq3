
do (jQuery) ->

  $ = jQuery

  $.fn.disable = () ->
    $(@).attr('disabled','true')

  $.fn.enable = () ->
    $(@).removeAttr('disabled')

  # require 'coffeekup'

  coffeekup_helpers =
  
    checkbox: (attrs) ->
      attrs.type = 'checkbox'
      attrs.name = attrs.id
      attrs.value ?= 'true'
      attrs.class ?= 'normal'
      label  for:attrs.name, class:attrs.class, ->
        span attrs.title
        input attrs
        
    textbox: (attrs) ->
      attrs.type = 'text'
      attrs.name = attrs.id
      attrs.class ?= 'normal'
      label  for:attrs.name, class:attrs.class, ->
        span attrs.title
        input attrs
        
    text_area: (attrs) ->
      attrs.name = attrs.id
      attrs.rows ?= 3
      attrs.cols ?= 3
      attrs.class ?= 'normal'
      label  for:attrs.name, class:attrs.class, ->
        span attrs.title
        textarea attrs
        
  $.compile_template = (template) ->
    CoffeeKup.compile template, hardcode: coffeekup_helpers
    
  $.fn.auto_add = () ->

    table = @

    # First hide the template lines and add a "delete" button
    $('.template',table)
      .hide()
      .append '<td><div class="del ui-icon ui-icon-closethick">remove</div></td>'

    # This function adds a line to an existing table.
    add_line = ->

      # Count the number of data lines
      rank = 0
      $('tr.data',table).each -> rank++

      # Create a new row from the template
      row = $('.template',table)
        .clone()
        .removeClass('template')
        .addClass('data')
        .show()
        .appendTo(table)

      $('input,select',row).each ->
        $(@).attr 'name', (index,name)->
          return name.replace '*', rank

      # Make the button active
      $('.del',row).click ->
        row.remove()
        return false

      return

    $('tr:first',table)
      .append '<th><div class="add ui-icon ui-icon-plusthick">add line</div></th>'
    $('.add',table)
      .click -> add_line()

    # Start by inserting one row.
    add_line()

  return
