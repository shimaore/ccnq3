#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'host.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
vm   = require 'vm'

cdb         = require process.cwd()+'/../lib/cdb.coffee'
cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'

filter_name = "host/hostname"
hostname = os.hostname()
filter_params =
  hostname: hostname

cdb_changes.monitor config.provisioning_couchdb_uri, filter_name, filter_params, (p) ->
  if p.error? then return util.log(p.error)

  # p.runnables is a ring with new runnables at the start of the list
  # and old ones being pushed at the back.

  # Only run the first one if it has not been ran yet.
  runnable = shift p.runnables?
  # None is available
  return if not runnable?
  # Already ran the last one
  return if runnable.result?

  runnable.result =
    hostname: hostname
    code: runnable.code
    start: Date.now()
  try
    vm.runInNewContext(code,{host:p})
  catch error
    runnable.result.error = error
  finally
    runnable.result.end = Date.now()
    runnable.result.freemem = os.freemem()
    runnable.result.loadavg = os.loadavg()

  # Put this one at the end of the ring
  p.push runnable

  cdb.put p, (r) ->
    if r.error? then return util.log(r.error)
