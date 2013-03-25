#!/usr/bin/env coffee

port = 35984

require('zappajs') port, ->
  @include './content.coffee'
