Overview
========

This is a CCNQ3 application

    ccnq3 = require 'ccnq3'

which implements an AMQP agent for OpenSIPS.

    ccnq3.amqp (c) ->

Registration Status
===================

The agent provides registration status for a given user.

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

Registration Status Handler
---------------------------

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

      command = ccnq3.opensips.command 'ul_show_contact',
        'location',
        request.username

      ccnq3.opensips.mi null, mi_port, command, (error,response) ->

        if error
          return cb {error}

        result = ccnq3.opensips.parse response

If successful we get one or more Contact entries which look like
```
Contact:: <sip:..@...>;q=;expires=726;flags=..;cflags=..;socket=...;methods=...;user_agent=<...>
```

We rewrite them as objects

        clean_value = (s) ->
          return s if typeof s isnt 'string'
          if s[0] is '<' and s[s.length-1] is '>'
            s.substr(1,s.length-2)
          else
            s

        for r in result.Contact
          m = r.value
          [uri,params...] = m.split /;/
          r.uri = clean_value uri
          for p in params
            [key,value] = p.split /[=]/
            r[key] = clean_value value

and remove the original text response.

          delete r.value

        cb result.Contact

Tools
=====

We need access to the local configuration,

    config = null

it is loaded once at startup.

    ccnq3.config (c) -> config = c
