###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

# Load Configuration
fs = require('fs')
config_location = 'confirm.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def config: config

# Load CouchDB
cdb = require process.cwd()+'/../../../lib/cdb.coffee'

def users_cdb: cdb.new (config.users_couchdb_uri)

# Content

helper confirm_registration: (cb) ->
  db = users_cdb
  db.get "org.couchdb.user:#{@email}", (p) =>
    if p.error
      return error p.error

    if not p.confirmation_code? or not p.confirmation_expires?
      return error 'Nothing to confirm.'

    if p.confirmation_expires < (new Date()).valueOf()
      p.confirmation_code = Math.random()
      p.confirmation_expires = (new Date()).valueOf() + 2*24*3600*1000
      return db.put params, (r) ->
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
    db.put p, (r) ->
      if r.error?
        return error r.error
      else
        cb(p)

get '/register/confirm.html': ->
  if @email? and @code?
    confirm_registration (p) ->
      session.logged_in = p.name
      redirect config.post_register_confirmation_uri
  else
    page 'register_confirm'

view register_confirm: ->
  @title = 'Please confirm'

  form id: 'register', class: 'main validate', method: 'get', ->
    div ->
      label for: 'email', -> 'Email'
      input id: 'email', name: 'email'
    div ->
      label for: 'code', -> 'Confirmation code'
      input id: 'code', name: 'code'
    div ->
      input type: 'submit', value: 'Confirm'

