###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

client layout: ->
  # jqueryui
  $(document).ready ->
    $('#content').addClass('ui-widget')
    $('form.main').addClass('ui-widget-content')
    $('button,input[type="submit"],input[type="reset"]').button()

  # validate
  $(document).ready ->
    $("form.validate").validate();

view 'error': ->
  @title = 'Error'

  h1 @title
  div id: 'error', -> 'An errror occurred. Please try again.'
  div id: 'info', -> @error

layout 'widget': ->
  html -> @content

layout ->
  default_scripts = [
    '/public/javascripts/jquery',
    '/public/javascripts/jquery-ui',
    '/public/javascripts/jquery.validate',
    # '/public/javascripts/jquery.datatables',  # not included by default
    # '/public/javascripts/jquery.deserialize', # not included by default
    '/layout',
  ]
  default_stylesheets = [
    '/public/stylesheets/style',
    '/public/stylesheets/jquery-ui',
    # '/public/stylesheets/datatables',  # not included by default
  ]


  doctype 5
  html ->
    head ->
      title @title if @title
      # Send styling first
      for s in default_stylesheets
        link rel: 'stylesheet', href: s + '.css'
      if @stylesheets
        for s in @stylesheets
          link rel: 'stylesheet', href: s + '.css'
      link(rel: 'stylesheet', href: @stylesheet + '.css') if @stylesheet
      style @style if @style
      # Then send scripts
      for s in default_scripts
        script src: s + '.js'
      if @scripts
        for s in @scripts
          script src: s + '.js'
      script(src: @script + '.js') if @script

    body ->
      h1 @title

      noscript -> div class: 'error', -> 'Please enable Javascript in your web browser.'

      if @log
        div id: 'log', -> @log

      div id: 'content', -> @content

# Note: Must add 'layout' option to 'render' for alternative layouts
