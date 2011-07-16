
$(document).ready ->

    load = (selector,url,cb)->
        $.ajax
          url: url
          dataType: 'text'
          success: (data)->
            try
              $(selector).html CoffeeKup.render data
            catch error
              console.log "CoffeKup says: #{error} in #{data}"
            cb?() unless error?
          error: (_jq,status) ->
            $('body').html "Error: #{status}"

    app = $.sammy 'body', ->
      @get '#/', ->
        load 'body', 'widgets/index.coffee', ->
          editor = ace.edit('editor')
          # editor.setTheme('ace/theme/textmate')
          JavaScriptMode = require("ace/mode/javascript").Mode
          editor.getSession().setMode(new JavaScriptMode())
          editor.getSession().setValue('Hello world')
          editor.getSession().setTabSize(2)

      @get '#/load', ->
        $.get @uri, (data) ->
          editor = ace.edit('editor')
          editor.getSession().setValue(data)
          if @uri.match /\.js$/
            Mode = require("ace/mode/javascript").Mode
            editor.getSession().setMode(new Mode())
          if @uri.match /\.coffee$/
            Mode = require("ace/mode/coffeescript").Mode
            editor.getSession().setMode(new Mode())
          if @uri.match /\.html$/
            Mode = require("ace/mode/html").Mode
            editor.getSession().setMode(new Mode())
          if @uri.match /\.css$/
            Mode = require("ace/mode/css").Mode
            editor.getSession().setMode(new Mode())


      @get '#/save', ->

    app.run '#/'

