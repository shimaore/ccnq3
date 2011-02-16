
# Additional modules for the zappa server

express = require 'express'

app().http_server.use express.favicon()
app().http_server.use express.methodOverride()
app().http_server.use express.logger()

