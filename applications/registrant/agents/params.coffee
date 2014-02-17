fs = require 'fs'
module.exports = (p,config) ->
  config ?= p
  base_path = "./opensips"
  model = 'registrant'

  params = {}
  for _ in ['default.json',"#{model}.json"]
    do (_) ->
      data = require "#{base_path}/#{_}"
      params[k] = data[k] for own k of data

  params.opensips_base_lib = base_path
  params.notify_via_rabbitmq ?= "#{config.amqp}/logging".replace(/^amqp/,'rabbitmq') if config.amqp?

  params[k] = p[k] for own k of p

  params.mi_port = params.proxy_port + 30000 # i.e. 35070 etc.
  params.runtime_opensips_cfg = "#{params.runtime_opensips_cfg}.#{params.proxy_port}"

  return params
