  $(document).ready ->

    load = (selector,url,cb)->
        $.ajax
          url: url
          dataType: 'text'
          success: (data)->
            try
              $(selector).html CoffeeKup.render data
            catch error
              # context.log "CoffeKup says: #{error} in #{data}"
            cb?() unless error?
          error: (_jq,status) ->
            $('body').html "Error: #{status}"

    app = $.sammy 'body', ->
      @get '#/', (context)->
        load 'body', 'widgets/index.coffee'
      @get '#/form', ->
        $('#content').html "Sammy is working"

    app.run '#/'
