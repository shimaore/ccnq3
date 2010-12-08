def req: require 'request'

def _sql: (_uri,_sql,_p,cb) ->
  data =
    sql: _sql
    params: _p

  options =
    method:  'POST'
    uri:     _uri
    headers: {accept:'application/json','content-type':'application/json'}
    body:    new Buffer(JSON.stringify(data))
  req options, (error,response,body) ->
    if(!error && response.statusCode == 200)
      cb(JSON.parse(body))
    else
      cb({error:error})

def _dancer_session: (_uri,cb) ->
  if not cookies
    return cb({error:"No cookies"})
  id = cookies["dancer.session"]
  options =
    uri:      _uri+'/'+querystring.escape(id)
    headers:  {accept:'application/json'}
  req options, (error,response,body) ->
    if(!error && response.statusCode == 200)
      cb(JSON.parse(body))
    else
      cb({error:error})

def _user_info: (_uri,user_id,cb) ->
  options =
    method:   'GET'
    uri:      _uri+'/'+querystring.escape(user_id)
    headers:  {accept:'application/json'}
  req options, (error,response,body) ->
    if(!error && response.statusCode == 200)
      cb(JSON.parse(body))
    else
      cb({error:error})
