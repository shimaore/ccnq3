
# Additional modules for the zappa server

express = require 'express'
app().http_server.configure =>
  app().http_server.use express.staticProvider("#{process.cwd()}/public")
  app().http_server.use express.favicon()
  app().http_server.use require("#{process.cwd()}/lib/bodyDecoder")()
  app().http_server.use express.methodOverride()
  app().http_server.use express.cookieDecoder()
  app().http_server.use express.session()
  app().http_server.use express.logger()

require('connect/middleware/bodyDecoder').decode['application/x-www-form-urlencoded'] = require('form2json').decode;
