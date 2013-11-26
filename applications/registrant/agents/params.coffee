fs = require 'fs'
module.exports = (p) ->
  base_path = "./opensips"
  model = 'registrant'

  params = {}
  for _ in ['default.json',"#{model}.json"]
    do (_) ->
      data = require "#{base_path}/#{_}"
      params[k] = data[k] for own k of data

  params.opensips_base_lib = base_path
  params.notify_via_rabbitmq ?= "#{config.amqp}/logging" if config.amqp?

  params[k] = p.registrant[k] for own k of p.registrant

  return params
