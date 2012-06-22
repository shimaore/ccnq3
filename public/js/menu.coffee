# Currently unused.
#
jQuery ($) ->

  $.menu ?= {}

  selector = '#menu_container'

  $.menu.render = (menu) ->
    switch typeof menu

      when 'function' # label or sub-menu
        menu()

      when 'string' # HTML
        $('<span>').html menu

      when 'object'

        # Menu entry (hash)
        if menu.label?
          label = $.menu.render menu.label

          # Menu header
          if menu.href
            r = $('<a>').attr('href',menu.href).append label
          else
            r = label

          # Sub-menu
          if menu.menu?
            return [r, $.menu.render menu.menu]

          return r

        # Menu entries (array)
        else
          r = $('<ul>')
          (r.append $('<li>').append $.menu.render sub_menu ) for sub_menu in menu
          return r

      else
        console.log "Cannot use #{typeof menu} menu."

  $.menu.set = (new_menu) ->
    menu_content = $.menu.render new_menu
    $(selector).empty().append menu_content
    $("#{selector} ul").attr 'id', 'menu'
