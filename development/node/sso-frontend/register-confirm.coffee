
def password_charset: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".split('')

helper random_password: (l) ->
      return '' if l is 0
      return random_password(l-1)+password_charset[Math.floor(Math.random()*password_charset.length)]

use crypto

helper create_account: (p,cb) ->
  # Note: This could be replaced with an LDAP store, etc.
  db = users_cdb
  p.salt = crypto.createHash('sha1').update(Math.random()).digest('hex')
  p.password_sha = crypto.createHash('sha1').update(p.password,p.salt).digest('hex')
  delete p.password
  delete p._rev
  db.put p, cb

helper confirm_registration: (password,cb) ->
  db = portal_cdb
  db.get @email, (p) =>
    if p.error
      return error p.error

    if not p.confirmation_code? or not p.confirmation_expires?
      return error 'Nothing to confirm.'

    if p.confirmation_expires < (new Date()).valueOf()
      p.confirmation_code = crypto.createHash('sha1').update(Math.random()).digest('hex')
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
    delete p.confirmation_code
    delete p.confirmation_expires
    create_account p, (r) ->
      if r.error?
        return error r.error
      else
        cb(p)

get '/register/confirm.html': ->
  if @email? and @code?
    @new_password = random_password(16)
    confirm_registration @new_password, (p) ->
      page 'register_confirmed'
  else
    page 'register_confirm'

get '/register/confirm/:email/:code': ->
  if @email? and @code?
    @new_password = random_password(16)
    confirm_registration @new_password, (p) ->
      page 'register_confirmed'
  else
    page 'register_confirm'

view 'register_confirm': ->
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

view 'register_confirmed': ->
  @title = 'Your new account has been confirmed'

  div -> "Your new password is: #{@new_password}"
