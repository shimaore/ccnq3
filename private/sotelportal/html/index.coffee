$(document).ready ->

    app = $.sammy 'body', ->

      @get '#/', ->
        $('body').brew 'widgets/index'

      @get '#/nda', ->
        $('#nda').brew 'widgets/nda'


    app.run '#/'
