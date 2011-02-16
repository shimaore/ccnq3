#!/usr/bin/env zappa

def jid: 'stephane@shimaore.net'

def xmpp: require '/home/stephane/Artisan/Telecoms/ccnq3/toy/bob/xmpp-component.js'

get '/': -> render 'default'

get '/counter': -> "# of messages so far: #{app.counter}"

at connection: ->
  puts "Connected: #{id}"
  app.counter ?= 0
  send_stanza = (text) -> send 'said', id: jid, text: text
  xmpp.add(id,send_stanza,jid)
  xmpp.send(id,"Connected")
  # broadcast 'connected', id: id

at disconnection: ->
  puts "Disconnected: #{id}"
  # broadcast 'disconnected', id: id
  xmpp.send(id,"Disconnected")
  xmpp.remove(id)

msg said: ->
  puts "#{id} said: #{@text}"
  app.counter++
  send 'said', id: id, text: @text
  # broadcast 'said', id: id, text: @text
  xmpp.send(id,@text)

client ->
  $(document).ready ->
    socket = new io.Socket()

    socket.on 'connect',    -> $('#log').append '<p>Connected</p>'
    socket.on 'disconnect', -> $('#log').append '<p>Disconnected</p>'
    socket.on 'message', (raw_msg) ->
      msg = JSON.parse raw_msg
      if msg.connected then $('#log').append "<p>#{msg.connected.id} Connected</p>"
      else if msg.said then $('#log').append "<p>#{msg.said.id}: #{msg.said.text}</p>"

    $('form').submit ->
      socket.send JSON.stringify said: {text: $('#box').val()}
      $('#box').val('').focus()
      false

    socket.connect()
    $('#box').focus()

view ->
  @title = 'Nano Chat'
  @scripts = ['/javascripts/jquery', '/socket.io/socket.io', '/default']

  h1 @title
  div id: 'log'
  form ->
    input id: 'box'
    button id: 'say', -> 'Say'
