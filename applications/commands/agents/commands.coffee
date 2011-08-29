#!/usr/bin/env coffee
###
(c) 2011 Stephane Alnet
Released under the AGPL3 license
###

# The "commands" database is used to record actions that are ran
# only once. They normally should only be used to observe, but not
# modify the system ("GET"-type operations), since all system
# changes MUST be handled via the provisioning database.

ccnq3_logger  = require 'ccnq3_logger'
vm            = require 'vm'

run_handler = (q) ->

  q.start: Date.now()

  try
    # Similarly to CouchDB, a runnable must return a function.
    f = vm.runInNewContext(q.code)
    # The function might alter p or simply return a value.
    q.returns = f(p)
  catch error
    result.error = error
  finally
    q.end = Date.now()
    q.freemem = os.freemem()
    q.loadavg = os.loadavg()

    ccnq3_logger.log result

# Main

util = require 'util'
config = require('ccnq3_config').config
cdb_changes = require 'cdb_changes'

options =
  uri: config.commands.couchdb_uri
  filter_name: "commands/hostname"
  filter_params:
    hostname: config.host

cdb_changes.monitor options, (p) ->
  if p.error? then return util.log p.error

  run_handler p
