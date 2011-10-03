    # db_dbase.c lists: int, double, string, str, blob, date; str and blob are equivalent for this interface.
    column_types =
      usrloc:
        username: 'string'
        domain: 'string'
        contact: 'string'
        received: 'string'
        path: 'string'
        expires: 'date'
        q: 'double'
        callid: 'string'
        cseq: 'int'
        last_modified: 'date'
        flags: 'int'
        cflags: 'int'
        user_agent: 'string'
        socket: 'string'
        methods: 'int'
      version:
        table_name: 'string'
        table_version: 'int'
      dr_gateways:
        gwid: 'int'
        type: 'int'
        address: 'string'
        strip: 'int'
        pri_prefix: 'string'
        attrs: 'string'
        probe_mode: 'int'
        description: 'string'
      dr_rules:
        ruleid: 'int'
        # keys
        groupid: 'string'
        prefix: 'string'
        priority: 'int'
        # others
        timerec: 'string'
        routeid: 'string'
        gwlist: 'string'
        attrs: 'string'
        description: 'string'
      dr_gw_lists:
        id:'int'
        gwlist:'string'
      dr_groups:
        username:'string'
        domain:'string'
        groupid:'int'
      domain:
        domain: 'string'
      subscriber:
        username: 'string'
        domain: 'string'
        password: 'string'
        ha1: 'string'
        ha1b: 'string'
        rpid: 'string'
      avpops:
        uuid: 'string'
        username: 'string'
        domain: 'string'
        attribute: 'string'
        type: 'int'
        value: 'string'
      location:
        username:'string'
        domain:'string'
        contact:'string'
        received:'string'
        path:'string'
        expires:'date'
        q:'double'
        callid:'string'
        cseq:'int'
        last_modified:'date'
        flags:'int'
        cflags:'int'
        user_agent:'string'
        socket:'string'
        methods:'int'


    quoted_value = (t,x) ->
      # No value: no quoting.
      if not x?
        return ''

      # Expects numerical types => no quoting.
      if t is 'int' or t is 'double'
        # assert(parseInt(x).toString is x) if t is 'int' and typeof x isnt 'number'
        # assert(parseFloat(x).toString is x) if t is 'double' and typeof x isnt 'number'
        return x

      # assert(t is 'string')
      if typeof x is 'number'
        x = x.toString()
      if typeof x isnt 'string'
        x = JSON.stringify x
      # assert typeof x is 'string'

      # Assumes quote_delimiter = '"'
      return '"'+x.replace(/"/g, '""')+'"'


    field_delimiter = "\t"
    row_delimiter = "\n"

    line = (a) ->
      a.join(field_delimiter) + row_delimiter

    first_line = (types,c)->
      return line( types[col] for col in c.split ',' )

    value_line = (types,hash,c)->
      return line( quoted_value(types[col], hash[col]) for col in c.split ',' )

#    exports.from_array = (n,t,c) ->
#      if not t? or t.length is 0 then return ''
#      types = column_types[n]
#      first_line(types,c) + ( value_line(types,l,c) for l in t ).join('')

    exports.from_hash = (n,h,c) ->
      if not h? then return ''
      if n is 'avpops'
        h =
          value: h
          attribute: h.type
          type: 2
      if n is 'dr_gateways'
        h.type = h.gwtype

      types = column_types[n]
      first_line(types,c) + value_line(types,h,c)
