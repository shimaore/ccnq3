  $(document).ready ->

    app = $.sammy 'body', ->
      @get '#/', (context)->
        $.ajax
          url: 'index.coffeekup'
          dataType: 'text'
          success: (data)->
            try
              $('body').html CoffeeKup.render data
            catch error
              context.log "CoffeKup says: #{error} in #{data}"
          error: (_jq,status) ->
            $('body').html "Error: #{status}"

      @get '#/form', ->
        $('#content').html "Sammy is working"

    app.run '#/'
 
