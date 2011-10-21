# user_management.coffee

do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  profile = $(container).data 'profile'

  user_management_tpl = $.compile_template ->

    div ->
      table id:'user_table', cellpadding:0, cellspacing:0, border:0, class:"display", ->
        thead ->
          tr ->
            th 'Name'
            th 'Email'
            th 'Phone'


  $(document).ready ->

    $('#user_table').dataTable
      # jQuery-UI styling
      bJQueryUI: true
      sPaginationType: 'full_numbers'
      # Ajax source
      bProcessing: true
      sAjaxSource: '_design/portal/_list/datatable/users?fields=name+email+phone'

    $.sammy container, ->

      model = @createModel 'user_management'

      @get '#/user_management', ->

        @swap user_management_tpl
