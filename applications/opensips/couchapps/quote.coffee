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
        sip_instance: 'string'
      version:
        table_name: 'string'
        table_version: 'int'
      dr_gateways:
        id: 'int'
        gwid: 'string'
        type: 'int'
        address: 'string'
        strip: 'int'
        pri_prefix: 'string'
        attrs: 'string'
        probe_mode: 'int'
      dr_rules:
        ruleid: 'int'
        # keys
        groupid: 'string'
        prefix: 'string'
        timerec: 'string'
        priority: 'int'
        # others
        routeid: 'string'
        gwlist: 'string'
        attrs: 'string'
      dr_carriers:
        id: 'int'
        carrierid: 'string'
        gwlist: 'string'
        flags: 'int'
        attrs: 'string'
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
      registrant:
        registrar:'string'
        proxy:'string'
        aor:'string'
        third_party_registrant:'string'
        username:'string'
        password:'string'
        binding_URI:'string'
        binding_params:'string'
        expiry:'int'
        forced_socket:'string'

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
      return line( types[col] for col in c )

    value_line = (types,n,hash,c)->
      if n is 'avpops'
        # Shorten output a little since these are not used
        # (avpops has a limited input buffer size).
        delete hash._id
        delete hash._rev
        delete hash._revisions
        # Build a proper "avpops" response.
        hash =
          value: hash
          attribute: hash.type
          type: 2
      if n is 'dr_rules'
        hash.routeid ?= 0
        hash.timerec ?= ""
        hash.priority ?= 1
        hash.attrs ?= ""
      if n is 'dr_carriers'
        hash.id ?= 1
        hash.flags ?= 1
        hash.attrs ?= ""
      if n is 'dr_gateways'
        hash.id ?= 1
        hash.gwtype ?= 0
        hash.type = hash.gwtype
        hash.probe_mode ?= 0
        hash.strip ?= 0
      if n is 'dr_groups'
        hash.groupid = hash.outbound_route # alternatively set the "drg_grpid_col" parameter to "outbound_route"
      return line( quoted_value(types[col], hash[col]) for col in c )

    exports.column_types = column_types
    exports.first_line = first_line
    exports.value_line = value_line
