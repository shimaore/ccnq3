Overview
--------

This is an AMQP agent for OpenSIPS.

Registration Status
-------------------

The agent provides registration status for a given user.

    ccnq3.amqp (c) ->
      c.exchange 'registration', {type:'topic',durable:true}, (e) ->

The request comes as an AMQP event.

        c.queue "registration-request-#{config.host}", (q) ->
          q.bind e, 'request'
          q.subscribe (request) ->

The request contains the name of the queue to which we should reply.

            {reply_to} = request

OpenSIPS is queried for the response.

            registration_status config, request, (response) ->

The response is sent back over AMQP.

              c.publish reply_to, response

### Registration Status Handler ###

This part actual sends the command to OpenSIPS and parses the response.

    registration_status = (config,request,cb) ->

FIXME: The default `mi_port` is actually recorded by default in the opensisp.model.

      mi_port = config.opensips.mi_port ? 30000

Quoting from the documentation for OpenSIPS' `mi_datagram` module:
The external commands issued via DATAGRAM interface must follow the following syntax:
* `request = first_line (argument '\n')*`
* `first_line = ':'command_name':''\n'`
* `argument = (arg_name '::' (arg_value)? ) | (arg_value)`
* `arg_name = not-quoted_string`
* `arg_value = not-quoted_string | '"' string '"'`
* `not-quoted_string = string - {',",\n,\r}`

      command = [
        ':ul_show_contact:'
        'location'
        request.username
      ].map( (x) -> x+"\n" ).join ''

      ccnq3.opensips.mi null, mi_port, command, (error,response) ->

        if error
          return cb {error}

Parse the response (a Buffer instance):

        response = response.toString 'utf-8'

The first line is a status line, while any remaining line should contain data.

        [status,lines] = response.split /\n/

First handle errors. We might for example get '404 AOR not found' or some other message.

        if status isnt '200 OK'
          cb {error:'status', status}
          return

If successful we get a line (or lines?) which looks like
```
Contact:: <sip:..@...>;q=;expires=726;flags=..;cflags=..;socket=...;methods=...;user_agent=<...>
```
There's a more generic format for parsing; we don't use it here.

        result = {contacts:[]}

        for line in lines
          m = line.match /^Contact:: (.*)$/
          [uri,params...] = m[1].split /;/
          r = {uri}
          for p in params
            [key,value] = p.split /[=]/
            r[key] = value
          result.contacts.push r

        cb result

Tools
-----

This is a CCNQ3 application.

    ccnq3 = require 'ccnq3'

We need access to the local configuration,

    config = null

it is loaded once at startup.

    ccnq3.config (c) -> config = c
