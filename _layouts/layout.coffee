doctype 5
html ->
  head ->
    title @title if @title
    if @scripts
      for s in @scripts
        script src: s + '.js'
    script(src: @script + '.js') if @script
    if @stylesheets
      for s in @stylesheets
        link rel: 'stylesheet', href: s + '.css'
    link(rel: 'stylesheet', href: @stylesheet + '.css') if @stylesheet
    style @style if @style
  body ->
    div id:'container', @body
