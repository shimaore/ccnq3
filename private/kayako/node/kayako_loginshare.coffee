# Zappa

fs = require('fs')
config_location = 'kayako_loginshare.config'
kayako_loginshare_config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def kayako_loginshare_config: kayako_loginshare_config

json_req = require process.cwd()+'/../../../lib/json_req.coffee'

def json_req: json_req

using 'querystring'

def kayako_error_msg: (msg) ->
  msg =? 'Invalid Username or Password'
  """
  <?xml version="1.0" encoding="UTF-8"?>
  <loginshare>
    <result>0</result>
    <message>#{msg}</message>
  </loginshare>
  """

post '/loginshare': ->
  q =
    uri: kayako_loginshare_config.login_uri
    body:
      username: @username
      password: @password

  json_req.request q, (p) ->
    if p.error?
      return send kayako_error_msg(p.error)

    q.uri = kayako_loginshare_config.profile_uri
    delete q.body

    json_req.request q, (p) ->
      if p.error?
        return send kayako_error_msg()

      send """
           <?xml version="1.0" encoding="UTF-8"?>
           <loginshare>
             <result>1</result>
             <user>
               <usergroup>Registered</usergroup>
               <fullname>#{p.first_name} #{p.last_name}</fullname>
               <emails>
                 <email>#{p.email}</email>
               </emails>
               <phone>#{p.phone}</phone>
             </user>
           </loginshare>
           """
