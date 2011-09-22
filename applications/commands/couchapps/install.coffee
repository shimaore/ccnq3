#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
require('ccnq3_config').get (config)->

  # ==== Commands ====
  commands_uri = config.commands.couchdb_uri
  commands = cdb.new(commands_uri)
  commands.create ->

    commands.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("commands_admin") if p.admins.roles.indexOf("commands_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles("commands_reader")    if p.readers.roles.indexOf("commands_reader") < 0
      p.readers.roles("commands_writer")    if p.readers.roles.indexOf("commands_reader") < 0
      p.readers.roles("host")               if p.readers.roles.indexOf("host") < 0

    push_script commands_uri, 'commands'

  # ==== Logger ====
  logger_uri = config.logger.couchdb_uri
  logger = cdb.new(logger_uri)
  logger.create ->

    logger.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("logger_admin")   if p.admins.roles.indexOf("logger_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("logger_reader") if p.readers.roles.indexOf("logger_reader") < 0
      p.readers.roles.push("logger_writer") if p.readers.roles.indexOf("logger_reader") < 0
      p.readers.roles.push("host")          if p.readers.roles.indexOf("host") < 0

    push_script logger_uri, 'logger'
