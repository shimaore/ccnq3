do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'
  host_username = (n) -> "host@#{n}"

  container = '#content'

  profile = $(container).data 'profile'
  selector = '#trace_request'

  log = (text,clear) ->
    if clear
      $('#trace_log').html text+"\n"
    else
      $('#trace_log').append text+"\n"

  trace_tpl = $.compile_template ->

    form id:'trace_request', method:'post', action:'#/trace', class:'validate', ->

      div id:'trace_log', class:'log'

      label for:'host', class:'normal', ->
        span 'Host'
        select name:'host', class:'required text', ->
          (option value:host, -> host) for host in @hosts

      textbox
        id:'call_id'
        title: 'Call-ID'

      textbox
        id:'from_user'
        title: 'From'
        class: 'digits'

      textbox
        id:'to_user'
        title: 'To'
        class: 'digits'

      checkbox
        id:'inline'
        title:'Display inline'

      textbox
        id:'days_ago'
        title: 'Days ago'
        class: 'digits required'
        value: '0'

      input type:'submit'

    $('form.validate').validate()

    div id:'packets_container', ->
      dl id:'packets'

  $(document).ready ->

    app = $.sammy container, ->

      model = @createModel 'host'

      @get '#/trace', ->

        model.view 'host/traces_hosts', (data) =>
          hosts = (row.key for row in data.rows)
          @swap trace_tpl {hosts:hosts}

      @post '#/trace', ->

        form_is_valid = $(selector).valid()
        form = $(selector).toDeepJson()

        if form_is_valid and (form.call_id? or form.from_user? or form.to_user?)
          log 'Submitting...', true

          form.format = if form.inline then 'json' else 'pcap'

          # Process:
          # 1. add a new entry in the host's traces.run hash
          # 2. wait a little, then try to download from the trace_proxy (at /roles/traces/:host/:port)
          # 3. for inline download, we need to format the output
          #    for pcap download, we need to open the file

          port = Math.floor(Math.random()*2000)+8000
          id = make_id 'host', form.host
          model.get id, (doc) ->
              doc.traces.run ?= {}
              if doc.traces.run[port]
                return log 'Sorry, try again'
              doc.traces.run[port] = form
              model.update id, doc,
                success: ->
                  $.ccnq3.push_document 'provisioning', ->
                    setTimeout wait_for_capture, 3000

          # Attempt to download the capture content
          wait_for_capture = ->
            url = "/roles/traces/#{encodeURIComponent form.host}/#{encodeURIComponent port}"

            # Do no re-submit this query
            model.get id, (doc) ->
              # doc.traces.run ?= {}
              # delete doc.traces.run[port]
              delete doc.traces.run
              model.update id, doc,
                success: ->
                  $.ccnq3.push_document 'provisioning', ->
                    log 'Submitted.'

            # For a PCAP file, simply redirect the browser
            if not form.inline
              return window.open url

            # For the JSON content, we must download it then render it
            $.getJSON( url, render_packets ).error -> setTimeout wait_for_capture, 3000

          # Do an HTML overview of the packets
          render_packets = (data) ->
            $('#packets').empty()
            log "Received #{data.length} packets.", true

            request_line_tpl = $.compile_template ->
              dt class:'request', ->

                  span class:'time', -> @['frame.time']

                  span class:'ip', ->
                    @['ip.src']+':'+(@['udp.srcport'] ? @['tcp.srcport'])

                  span '→'

                  span class:'ip', ->
                    @['ip.dst']+':'+(@['udp.dstport'] ? @['tcp.dstport'])

                  span class:'call-id', -> @['sip.Call-ID']

                  span class:'line', -> @['sip.Request-Line']

              dd class:'request', ->
                  span class:'from', -> @['sip.From']
                  span class:'to',   -> @['sip.To']

            status_line_tpl = $.compile_template ->
              dt class:'reply', ->

                  span class:'time', -> @['frame.time']

                  span class:'ip', ->
                    @['ip.dst']+':'+(@['udp.dstport'] ? @['tcp.dstport'])

                  span '←'

                  span class:'ip', ->
                    @['ip.src']+':'+(@['udp.srcport'] ? @['tcp.srcport'])

                  span class:'call-id', -> @['sip.Call-ID']

                  span class:'line', -> @['sip.Status-Line']

              dd class:'reply', ->
                  span class:'from', -> @['sip.From']
                  span class:'to',   -> @['sip.To']

            for packet in data
              do (packet) ->

                if packet['sip.Request-Line']
                  $(request_line_tpl packet).appendTo '#packets'

                if packet['Status-Line']
                  $(status_line_tpl packet).appendTo '#packets'

            # Make the Call-ID clickable.
            $('#packets').find('.call-id').click ->
              $('#call-id').val $(@).text()
              $('#from_user').val ''
              $('#to_user').val ''
              $('#trace_request').submit()

        else
          log 'One of the values is required.', true

        return
