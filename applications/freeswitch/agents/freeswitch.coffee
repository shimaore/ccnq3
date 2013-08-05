#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'
make_id = (t,n) -> [t,n].join ':'

request = require 'request'
fs = require 'fs'
save_uri_as = (uri,file,cb)->
  request uri, (e,r,b) ->
    if e?
      util.error "Error when updating #{file}: error=#{e}"
      return
    if r?.statusCode isnt 200
      util.error "Error when updating #{file}: statusCode=#{r.statusCode}"
      return
    # According to default installation scheme, we can write to the directory but not necessarily to the files.
    fs.unlink file, ->
      # Ignore unlink error, since the file might not have been there in the first place.
      # Write content to file
      fs.writeFile file, b, (e) ->
        if e?
          util.error "Error when updating #{file}: error=#{e}"
          return
        do cb

# Main

pico = require 'pico'
qs = require 'querystring'

require('ccnq3').config (config) ->

  # Aggregate back towards the main database if requested.
  require('./aggregate') config

  handler = (p) ->

    # 1. Generate new configuration files
    conf_dir = '/opt/ccnq3/freeswitch/conf'
    files =
      freeswitch_local_profiles:  "#{conf_dir}/local-profiles.xml"
      freeswitch_local_acl:       "#{conf_dir}/local-acl.xml"
      freeswitch_local_vars:      "#{conf_dir}/local-vars.xml"
      freeswitch_local_conf:      "#{conf_dir}/local-conf.xml"
      freeswitch_local_json_cdr:  "#{conf_dir}/local-json_cdr.xml"
      freeswitch_local_modules:   "#{conf_dir}/local-modules.xml"

    host_uri = qs.escape make_id 'host', config.host

    write_config_files = (cb) ->
      expected = 0
      for show, file of files
        do (show,file)->
          expected++
          save_uri_as "#{config.provisioning.local_couchdb_uri}/_design/freeswitch/_show/#{show}/#{host_uri}", file,  ->
            if --expected is 0 then cb?()
      return

    # 1b. Apply configuration changes
    apply_configuration_changes = (cb) ->
      fs_command 'reloadxml', ->
        fs_command 'reloadacl reloadxml', ->
          expected = 0
          for profile_name of p.sip_profiles
            do (profile_name) ->
              expected++
              fs_command "sofia profile #{profile_name} rescan reloadxml", ->
                util.log "Update sofia profile #{profile_name}"
                if --expected is 0 then cb?()

    # 2. Process any command
    process_commands = ->
      if p.sip_commands?
        (require './process-changes') p.sip_commands
      return

    write_config_files -> apply_configuration_changes -> process_commands()

  # Start with current configuration
  handler config

  # Monitor for changes and commands.
  db = pico config.provisioning.local_couchdb_uri
  options =
    since_name: "freeswitch #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  db.monitor options, handler
  return

# Start the CDR swiper
require './cdr-swiper'

# Start the CDR cleaner
require './cdr-cleaner'
