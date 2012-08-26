# aggregate.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

pico = require 'pico'

replicate = (config) ->

  # Replicate the local "cdr" database
  source_uri = cdr_uri = config.cdr_uri ? 'http://127.0.0.1:5984/cdr'
  # into the global one
  target_uri = config.cdr_aggregate_uri

  pico.replicate source_uri, target_uri, config.replicate_interval, 'cdr/not_deleted'

module.exports = replicate
