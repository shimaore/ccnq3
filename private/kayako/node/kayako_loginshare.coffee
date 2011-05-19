# Zappa

fs = require('fs')
config_location = 'kayako_loginshare.config'
kayako_loginshare_config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def kayako_loginshare_config: kayako_loginshare_config

json_req = require process.cwd()+'/../../../lib/json_req.coffee'
qs = require 'querystring'

post '/loginshare': ->
  base = kayako_loginshare_config.base
  basic_auth = new Buffer [@username,@password].join(':')
  id = "org.couchdb.user:#{@username}"

  q =
    uri: "#{base}/_users/#{qs.stringify(id)}"
    headers:
      authorization: "Basic #{basic_auth.toString('base64')}"

    json_req q, (p) ->
      if p.error? or not p._id
        return render 'loginshare-failed',  layout: 'loginshare'

      render 'loginshare-success', layout: 'loginshare', context: p

layout 'loginshare': ->
  """
  <?xml version="1.0" encoding="UTF-8"?>
  <loginshare>
  #{@content}
  </loginshare>
  """

view 'loginshare-failed': ->
  """
  <result>0</result>
  <message>Invalid Username or Password</message>
  """

view 'loginshare-success': ->
  """
  <result>1</result>
  <user>
      <usergroup>Registered</usergroup>
      <fullname>#{@first_name} #{@last_name}</fullname>
      <emails>
          <email>#{@email}</email>
      </emails>
      <phone>#{@phone}</phone>
  </user>
  """

