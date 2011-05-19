# Zappa

fs = require('fs')
config_location = 'kayako_loginshare.config'
kayako_loginshare_config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def kayako_loginshare_config: kayako_loginshare_config

json_req = require process.cwd()+'/../../../lib/json_req.coffee'

def json_req: json_req

using 'querystring'

def kayako_error_msg: (msg) ->
  msg ?= 'Invalid Username or Password'
  """
  <?xml version="1.0" encoding="UTF-8"?>
  <loginshare>
    <result>0</result>
    <message>#{msg}</message>
  </loginshare>
  """

post '/loginshare': ->
  q =
    method: 'POST'
    uri: kayako_loginshare_config.login_uri
    body:
      username: @username
      password: @password

  json_req.request q, (p,cookie) ->
    if p.error?
      return send kayako_error_msg(p.error)

    s =
      uri: kayako_loginshare_config.profile_uri
      headers:
        cookie: cookie

    json_req.request s, (r) ->
      if r.error?
        return send kayako_error_msg()

      send """
           <?xml version="1.0" encoding="UTF-8"?>
           <loginshare>
             <result>1</result>
             <user>
               <usergroup>Registered</usergroup>
               <fullname>#{r.first_name} #{r.last_name}</fullname>
               <emails>
                 <email>#{r.email}</email>
               </emails>
               <phone>#{r.phone}</phone>
             </user>
           </loginshare>
           """
