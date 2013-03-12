# If mod_json_cdr cannot access CouchDB it will save the JSON CDRs
# in /opt/ccnq3/freeswitch/cdr (as set by the ccnq3-freeswitch Debian
# package).
dirname = '/opt/ccnq3/freeswitch/cdr'
# The filenames created consist of a UUID plus `.cdr.json`.
cdr_pattern = /\.cdr\.json$/
# A minute is 60000 milliseconds.
minute = 60*1000

fs = require 'fs'
path = require 'path'
pico = require 'pico'

# When CDR files are saved in that directory we need to upload them
# back to CouchDB.
require('ccnq3').config (config) ->

  # When a new file is detected,
  handle_file = (filename) ->
    # We first confirm that it is a JSON CDR file
    if filename.match cdr_pattern
      # Then attempt to read it into memory
      fs.readFile filename, 'utf8', (err,data) ->
        if err
          console.log "readFile #{filename}: #{err}"
          return
        # If successful, we attempt to parse the JSON content
        try
          content = JSON.parse data
        catch e
          console.log "Not JSON in #{filename}"
          return
        # And attempt post that JSON content
        db.request.post json:content, (e,r,b) ->
          # This might fail because of network issues,
          if e
            console.log "Post #{filename}: #{e}"
            return
          # Or because of database issues.
          if not b.ok
            console.log "Post #{filename}: #{require('util').inspect b}"
            return
          # If successful, we finally attempt to remove the CDR file.
          fs.unlink filename, (err) ->
            if err
              console.log "unlink #{filename}: #{err}"
              return

  # We attemtpt to push the CDRs to config.cdr_uri, the same location
  # FreeSwitch's mod_json_cdr is configured to use.
  cdr_uri = config.cdr_uri
  if not cdr_uri?
    console.log "cdr-swiper: no cdr_uri, skipping"
    return
  db = pico cdr_uri

  # We can find the files by going over the directory that
  # contains them.
  read_all = ->
    fs.readdir dirname, (err,filenames) ->
      if filenames? and filenames.length
        for filename in filenames
          console.log "readdir: Found #{filename}"
          handle_file path.join dirname, filename

  # We attempt to upload the files which are present at startup,
  # then re-read at regular intervals.
  if config.cdr_swipe ? true
    read_all()
    setInterval read_all, config.cdr_swipe_interval ? 13*minute

  # We can also find files by monitoring the directory for changes,
  # so that we have a chance to retry right behind mod_json_cdr.
  if config.cdr_swipe_watch ? true
    fs.watch dirname, (event,filename) ->
      if filename?
        console.log "watch: Found #{filename}"
        handle_file path.join dirname, filename
