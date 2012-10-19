# aggregate.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

pico = require 'pico'

replicate = (config) ->

  # Replicate the local "cdr" database
  source_uri = config.cdr_uri
  # into the global one
  target_uri = config.cdr_aggregate_uri

  pico.replicate source_uri, target_uri, config.replicate_interval, 'cdr/not_deleted'

module.exports = replicate
