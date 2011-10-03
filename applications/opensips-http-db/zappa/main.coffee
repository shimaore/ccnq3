#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'
qs = require 'querystring'
request = require 'request'

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa config.opensips_proxy.port, config.opensips_proxy.hostname, {config}, ->

    cdb = require 'cdb'
    db = cdb.new config.provisioning.couchdb_uri

    loc_db = cdb.new config.opensips_proxy.usrloc_uri

    @use 'bodyParser', 'logger'

    unquote_value = (t,x) ->

      if not x?
        return x

      if t is 'int'
        return parseInt(x)
      if t is 'double'
        return parseFloat(x)
      # Not sure what the issue is, but we're getting garbage at the end of dates.
      if t is 'date'
        d = new Date(x)
        # Format expected by db_str2time() in db/db_ut.c
        # TODO: This requires opensips to be started in UTC, assuming
        #       toISOString() outputs using UTC (which it does in Node.js 0.4.11).
        return d.toISOString().replace 'T', ' '

      # string, blob, ...
      return x.toString()

    unquote_params = (k,v,table)->
      doc = {}
      names = k.split ','
      values = v.split ','
      types = column_types[table]

      doc[names[i]] = unquote_value(types[names[i]],values[i]) for i in [0..names.length]

      return doc

    pipe_req = (res,id) ->
      loc = config.provisioning.couchdb_uri + "/_design/opensips/_show/#{qs.stringify id}"
      request(loc).pipe(res)


    # Action!
    @get '/domain/': ->
      if @query.k is 'domain'
        pipe_req @res, "domain:#{@query.v}"
        return

      throw 'not handled'

    @get '/subscriber/': -> # auth_table
      if @query.k is 'username,domain'
        # Parse @v -- what is the actual format?
        [username,domain] = @query.v.split ","
        db.get "endpoint:#{username}@#{domain}", (t) =>
          if t.error then return @send ""
          @from_hash 'subscriber', t, @query.c
        return

      throw 'not handled'

    @get '/location/': -> # usrloc_table

      if @query.k is 'username'
        loc_db.get @query.v, (p) =>
          if p.error then return @send ""
          @from_hash 'usrloc', p, @query.c
        return

      if not @query.k?
        # Rewrite-me: will load everything in memory and build the reply in memory.
        # Instead use a CouchDB "list"
        #   loc_db.req "_design/http_db/_list/usrloc/_all_docs"
        # and figure out how to stream the response through Zappa.
        loc_db.req {uri:'_all_docs?include_docs=true'}, (t) =>
          @from_array 'usrloc', (u.doc for u in t.rows), @query.c
        return

      throw 'not handled'

    @post '/location': ->

      doc = unquote_params(@body.k,@body.v,'location')
      # Note: this allows for easy retrieval, but only one location can be stored.
      # Use "callid" as an extra key parameter otherwise.
      doc._id = "#{doc.username}@#{doc.domain}"

      if @body.query_type is 'insert' or @body.query_type is 'update'

        loc_db.head doc._id, (p) =>
          doc._rev = p._rev if p._rev?
          loc_db.put doc, (r) =>
            if r.error then return @send ""
            @send r._id
        return

      if @body.query_type is 'delete'

        loc_db.head doc._id, (p) =>
          if not p._rev? then return @send ""
          doc._rev = p._rev
          loc_db.del doc, (p) =>
            if p.error then return @send ""
            @send ""
        return

      throw "not handled #{util.inspect @}"

    @get '/avpops/': ->

      if @query.k is 'uuid,attribute'
        [uuid,attribute] = @query.v.split ','
        db.get "#{attribute}:#{uuid}", (p) =>
          if p.error then return @send ""
          avp =
            value: p
            attribute: attribute
            type: 2
          @from_hash 'avpops', avp, @query.c
        return

      if @query.k is 'username,domain,attribute'
        [username,domain,attribute] = @query.v.split ','
        db.get "#{attribute}:#{username}@#{domain}", (p) =>
          if p.error then return @send ""
          avp =
            value: p
            attribute: attribute
            type: 2
          @from_hash 'avpops', avp, @query.c
        return

      throw 'not handled'


    @get '/dr_gateways/': ->
      if not @query.k?
        db.req {uri:"#{config._id}/dr_gateways.json"}, (t) =>
          if t.error? then return @send ""
          @from_array 'dr_gateways', t, @query.c
        return
      ###
      my %attrs = ();
      $attrs{realm}    = $uac_realm if defined($uac_realm) && $uac_realm ne '';
      $attrs{user}     = $uac_user  if defined($uac_user ) && $uac_user  ne '';
      $attrs{pass}     = $uac_pass  if defined($uac_pass ) && $uac_pass  ne '';
      $attrs{force_mp} = $force_mp  if defined($force_mp ) && $force_mp  ne '';

      my $attrs = join(';', map { "$_=$attrs{$_}" } keys(%attrs) );
      ###

      throw 'not handled'

    @get '/dr_rules/': -> # ?c=ruleid,groupid,prefix,timerec,priority,routeid,gwlist,attrs
      if not @query.k?
        db.req {uri:"#{config._id}/dr_rules.json"}, (t) =>
          if t.error? then return @send ""
          @from_array 'dr_rules', t, @query.c
        return

      throw 'not handled'

    @get '/dr_groups/': ->

      if @query.k is 'username,domain'
        [username,domain] = @query.v.split ','
        # However we do not currently support "number@domain", so skip that.
        db.get "number/#{username}", (t) =>
          if t.error? then return @send ""
          @from_hash 'dr_groups', t, @query.c
        return

      throw 'not handled'

    @get '/dr_gw_lists/': -> # id,gwlist
      if not @query.k?
        db.req {uri:"#{config._id}/dr_gw_lists.json"}, (t) =>
          if t.error? then return @send ""
          @from_array 'dr_gw_lists', t, @query.c
        return

      throw 'not handled'

    @get '/version/': ->
      if @query.k is 'table_name' and @query.c is 'table_version'

        # Versions for OpenSIPS 1.7.0
        versions =
          location: 1006
          subscriber: 7
          dr_gateways: 4
          dr_rules: 3

        return "int\n#{versions[@query.v]}\n"

      throw 'not handled'
