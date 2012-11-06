#!/usr/bin/env coffee

port = 35984

require('zappajs') port, disable_io:true, ->
  @include './content.coffee'
