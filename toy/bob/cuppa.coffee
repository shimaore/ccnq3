#!/usr/bin/env zappa

get '/': 'hi'

# get '/:name': ->
#  "Hi, #{@name}"

get '/:foo': ->
  # @foo += '!'
  @title = "You said: #{@foo}!"
  render 'index', apply: 'blub'

view index: ->
  h1 'You said:'
  p @foo

client blob: ->
  alert 'hullo' + @foo

postrender blub: ->
  $('h1').remove() if @foo is 'barney'

layout ->
  doctype 5
  html ->
    head ->
      meta charset: 'utf-8'
      title "#{@title or 'Untitled'} | My awesome website"
      meta(name: 'description', content: @description) if @description?
      link rel: 'stylesheet', href: '/stylesheets/style.less'
      style '''
        body {font-family: sans-serif}
        header, nav, section, footer {display: block}
      '''
      script src: '/javascripts/jquery.js'
      script src: '/blob.js'
      # coffeescript ->
      #  $().ready ->
      #    alert 'Alerts are so annoying...'
    body -> @content


