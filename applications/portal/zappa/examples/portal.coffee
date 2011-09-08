#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

#
# Special rendering helpers
#
@include =
  # This gets everything started.
  coffee 'main.js': ->
    $(document).ready ->
      default_scripts = [
          '/public/js/jquery-ui',
          '/public/js/jquery.validate',
          '/u/content'
      ]
      for s in default_scripts
        $.getScript s + '.js'
