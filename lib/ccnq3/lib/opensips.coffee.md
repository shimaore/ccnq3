OpenSIPS tooling
================

    opensips =

The callback is called with (error,buffer).

      mi: (host = '127.0.0.1',port,command,cb) ->

Looking at the `mi_datagram` code source, it looks like the response must fit in a single datagram.
If this isn't the case then this code needs to be rewritten.

        client = dgram.createSocket 'udp4'

        client.on 'error', cb

        on_timeout = ->
          client.close()
          cb 'timeout'

        timeout = null

        client.on 'message', (msg,rinfo) ->
          clearTimeout timeout
          client.close()
          cb null, msg

        message = new Buffer(command)
        client.send message, 0, message.length, port, host, (e,bytes) ->
          if e
            cb e
          timeout = setTimeout on_timeout, 2000

Convert a command and its arguments (an array of values) into a single string command.

      command: (command,args...) ->
        make_value =  (x) ->
          if not x?
            return ''
          x = ''+x
          if x.match /['"\n\r]/
            '"'+x+'"'
          else
            x

        if args.length is 1 and typeof args[0] is 'object'
          # Named arguments
          o = args[0]
          arg_values = ("#{k}::#{make_value v}" for k,v of o)
        else
          # Positional arguments
          arg_values = args.map(make_value)

        [":#{command}:",arg_values...].map( (x) -> x+"\n" ).join ''

Parse the response (a Buffer instance or a string).
The object returned is an Array which might contain `value` fields beyond the numbered elements.

      parse: (response) ->
        if typeof response isnt 'string'
          response = response.toString 'utf-8'

The first line is a status line, while any remaining lines should contain data.

        [status,lines...] = response.split /\n/

First handle errors. We might for example get '404 AOR not found' or some other message.

        if status isnt '200 OK'
          return {error:'status', status}

        body = []
        path = []

        body_ref = (p,b = body) ->
          if p.length is 0
            return b

          name = p[0]
          b[name] ?= []
          body_ref p[1..], b[name]

The body may contain any number of (key,value) entries or (key,hash) entries.

        for line in lines when line isnt ''

          m = line.match /^(\t*)([^\t]*)$/
          if not m then return {error:'syntax',syntax:'invalid data line'}

          depth = m[1].length

In case of un-indent, retrieve the proper (shorter) path.

          while path.length > depth
            path.pop()

Parse the new content

          n = m[2].match /^(\w+)::\s*(.*)$/
          if n
            key = n[1]
            value = n[2]
          else
            key = null
            value = m[2]

          if value?
            ref = body_ref path
            if key?
              ref[key] ?= []
              o = []
              o.value = value
              ref[key].push o
            else
              ref.push value

          if key?
            path.push key

        return body


    module.exports = opensips
