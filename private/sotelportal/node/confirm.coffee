###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

# Load Configuration
fs = require('fs')
config_location = 'confirm.config'
confirm_config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def confirm_config: confirm_config

# Load CouchDB
cdb = require process.cwd()+'/../../../lib/cdb.coffee'

def users_cdb: cdb.new (confirm_config.users_couchdb_uri)

# Content

helper confirm_registration: (cb) ->
  users_cdb.get "org.couchdb.user:#{@email}", (p) =>
    if p.error?
      return error p.error

    if not p.confirmation_code? or not p.confirmation_expires?
      return error 'Nothing to confirm.'

    if p.confirmation_expires < (new Date()).valueOf()
      p.confirmation_code = Math.random()
      p.confirmation_expires = (new Date()).valueOf() + 2*24*3600*1000
      return users_cdb.put p, (r) ->
        if r.error?
          return error r.error
        else
          return error 'Your request is too old. A new confirmation code was sent to you.'

    if p.confirmation_code isnt @code
      return error 'Invalid confirmation code.'

    # Everything is OK
    p.status = 'confirmed'
    p.send_password = true
    delete p.confirmation_code
    delete p.confirmation_expires
    users_cdb.put p, (r) ->
      if r.error?
        return error r.error
      else
        cb(p)

get '/confirm.html': ->
  if @email? and @code?
    confirm_registration (p) ->
      redirect confirm_config.post_confirmation_uri
  else
    page 'confirm'

view confirm: ->
  @title = 'Please confirm'

  form id: 'confirm', class: 'main validate', method: 'get', ->
    div ->
      label for: 'email', -> 'Email'
      input id: 'email', name: 'email'
    div ->
      label for: 'code', -> 'Confirmation code'
      input id: 'code', name: 'code'
    div ->
      input type: 'submit', value: 'Confirm'

