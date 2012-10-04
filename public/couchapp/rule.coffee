do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  Inbox.register 'rule',

    list: (doc) ->
      return "Rule #{doc.rule} for outbound route #{doc.groupid} prefix '#{doc.prefix}' to gwlist '#{doc.gwlist}'"

    form: (doc) ->
      """
        <p>timerec #{doc.timerec}, priority #{doc.priority}, attrs #{doc.attrs}</p>
      """
