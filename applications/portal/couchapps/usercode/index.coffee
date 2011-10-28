###
# The default couchapp application.
###

$(document).ready ->

  container = '#content'

  # Only present if within portal (not in pure couchapp)
  profile = $(container).data('profile') ? {}

  app = $.sammy container, ->

    @template_engine = 'coffeekup'

    # Should use the proper database when used on a local replica, where
    # profile is empty.
    @use 'Couch', profile.user_database

    model = @createModel 'portal'

    model.extend
      require: (name,cb) =>
        $.getScript @db.uri + "_design/#{name}", cb

    $(container).data 'model', model

    @bind 'error.portal', (notice) ->
      console.log "Model error: #{notice.error}"
      $('#log').append "An error occurred: #{notice.error}"

    $('#log').ajaxError ->
      console.log "Ajax error: #{arguments[3]}"
      $(@).append arguments[3]

  # Load all the applications present in the _design documents.
  model = $(container).data 'model'

  # Retrieve the proper profile before starting the application.
  # (This allows for the profile to be available in other modules.)
  model.viewDocs "portal/user", (docs) =>
    profile = docs[0] ? {}
    $(container).data 'profile', profile

    user_is = (role) ->
      profile.roles?.indexOf(role) >= 0

    if user_is 'users_reader'
      $.getScript '/_users/_design/portal/user_management.js'

    app.db.allApps
      success: (appName, appPath, ddoc) ->
        # Do not load ourselves twice.
        if appName is 'portal' then return
        # Load all other applications.
        model.require "#{appName}/index.js"
