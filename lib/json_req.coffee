request = require 'request'

app_json = 'application/json'

@request = (options,cb) ->
  options.method ?= 'GET'
  options.headers ?= {}
  options.headers.accept = app_json
  if options.body?
    options.body = new Buffer(JSON.stringify(options.body))
    options.headers['Content-Type'] = app_json
  request options, (error,response,body) ->
    if not error and response.statusCode >= 200 and response.statusCode <= 299 and body?
      try
        value = JSON.parse(body)
      catch error
        value = {error:error}
      finally
        cb(value)
    else
      cb({error:error})
