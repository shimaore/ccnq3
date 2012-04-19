
do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  model = $(container).data 'model'

  model.require "host/endpoint.js"
  model.require "host/number.js"
  model.require "host/rule.js"
