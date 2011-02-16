#!/usr/bin/env zappa

app 'avistar2'

using 'fs'

def PASS_FILE: '/etc/ccn/mysql.pass'
def data: fs.readFileSync(PASS_FILE,'utf8').split("\n")

def db_access: { username: data[0], password: data[1] }

using 'mysql'

def HOST:

def db: mysql.createTCPClient(HOST,PORT)
db.auth(DB,db_access.username,db_access.password)

# postrender ...
  # remove fields that non-admins should not see

get '/': -> render 'default'

get '/:user_id': ->
  cmd = db.query("select * from user where user_id = ?",@user_id)
  cmd.addListener 'row', (r) =>
    @ = r
    render 'default'

put '/:user_id': ->
  cmd = db.execute("insert into ")

view ->
  @title = 'Session'
  @scripts = ['/javascripts/jquery', '/socket.io/socket.io', '/default']

  h1 @title
  div id: 'log'
  form ->
    input type: 'hidden', name: '_method', value: @user_id ? 'put' : 'post'
    input type:
    input type: 'submit'
