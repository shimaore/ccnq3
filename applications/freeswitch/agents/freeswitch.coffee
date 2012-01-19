#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

make_id = (t,n) -> [t,n].join ':'

esl = require 'esl'
fs_command = (cmd,cb) ->
  client = esl.createClient()
  client.on 'esl_auth_request', (req,res) ->
    res.auth 'CCNQ', (req,res) ->
      res.api cmd, (req,res) ->
        res.exit (req,res) ->
          client.end()
  if cb?
    client.on 'close', cb
  client.connect(8021, '127.0.0.1')

process_changes = (commands) ->

  for profile_name, command of commands when profile_name isnt 'opensips' and profile_name isnt 'freeswitch'
    switch command
      when 'start'
        fs_command "sofia profile #{profile_name} start"
      when 'restart'
        fs_command "sofia profile #{profile_name} restart reloadxml"
      when 'stop'
        fs_command "sofia profile #{profile_name} stop"

  ###
      when 'restart'
        fs_command "sofia profile #{profile_name} killgw", ->
          fs_command "sofia profile #{profile_name} rescan reloadxml"
      when 'stop'
        fs_command "sofia profile #{profile_name} killgw"
  ###

  # Following commands are not module-specific.
  if commands.freeswitch?
    switch commands.freeswitch
      when 'reload sofia'
        fs_command "unload mod_sofia", ->
          fs_command "load mod_sofia"
      when 'pause inbound'
        fs_command "fsctl pause inbound"
      when 'pause outbound'
        fs_command "fsctl pause outbound"
      when 'resume inbound'
        fs_command "fsctl resume inbound"
      when 'resume outbound'
        fs_command "fsctl resume outbound"
      when 'restart elegant'
        fs_command "fsctl restart elegant"
      when 'restart asap'
        fs_command "fsctl restart asap"

request = require 'request'
fs = require 'fs'
save_uri_as = (uri,file,cb)->
  fs.unlink file # According to default installation scheme, we can write to the directory but not necessarily to the files
  request(uri,cb).pipe(fs.createWriteStream(file))

# Main

util = require 'util'
cdb_changes = require 'cdb_changes'
qs = require 'querystring'

# FIXME keep last_rev in local storage
last_rev = ''

require('ccnq3_config').get (config) ->
  options =
    uri: config.provisioning.host_couchdb_uri
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  cdb_changes.monitor options, (p) ->
    if p.error? then return util.log(p.error)
    if p._rev is last_rev then return util.log "Duplicate revision"
    last_rev = p._rev

    # 1. Generate new configuration files
    conf_dir = '/opt/ccnq3/freeswitch/conf/'
    files =
      freeswitch_local_profiles:  "#{conf_dir}/local-profiles.xml"
      freeswitch_local_acl:       "#{conf_dir}/local-acl.xml"
      freeswitch_local_vars:      "#{conf_dir}/local-vars.xml"
      freeswitch_local_conf:      "#{conf_dir}/local-conf.xml"

    host_uri = qs.escape make_id 'host', config.host

    write_config_files = (cb) ->
      expected = 0
      for show, file of files
        do (show,file)->
          expected++
          save_uri_as "#{config.provisioning.local_couchdb_uri}/_design/freeswitch/_show/#{show}/#{host_uri}", file,  ->
            if --expected is 0 then cb?()

    # 1b. Apply configuration changes
    apply_configuration_changes = (cb) ->
      fs_command 'reloadxml', ->
        fs_command 'reloadacl reloadxml', ->
          expected = 0
          for profile_name of p.sip_profiles
            do (profile_name) ->
              expected++
              fs_command "sofia profile #{profile_name} rescan reloadxml", ->
                if --expected is 0 then cb?()

    # 2. Process any command
    process_commands = ->
      if p.sip_commands?
        process_changes p.sip_commands

    write_config_files -> apply_configuration_changes -> process_commands()
