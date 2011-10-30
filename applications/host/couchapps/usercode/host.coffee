make_id = (t,n) -> [t,n].join ':'


create host

  # two steps:
  #  1. create new user for the host
  #  2. create new entry in provisioning db

  username = "host@#{hostname}"

  users = cdb.new users_uri
  provisioning = cdb.new provisioning_uri

  salt = sha1_hex "a"+Math.random()
  password = sha1_hex "a"+Math.random()

  p =
    _id: "org.couchdb.user:#{username}"
    type: "user"
    name: username
    roles: ["host"]
    salt: salt
    password_sha: sha1_hex password+salt

  users.put p, (r)->
    if r.error?
      util.log util.inspect r
      throw "Creating user record for #{username}"

    # Add the host in the main CDB's provisioning table,
    # with two initialization runnables.

    config.type = "host"
    config.host = hostname
    config._id  = make_id 'host', hostname

    provisioning.put config, (r)->
      if r.error?
        util.log util.inspect r


