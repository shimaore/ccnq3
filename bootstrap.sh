#!/usr/bin/env bash
# (c) 2011 Stephane Alnet
# License: APGL3+

set -e
export LANG=
SRC=/opt/ccnq3/src
DIR=/etc/ccnq3
CONF=${DIR}/host.json
USER=ccnq3
# Apparently using /etc/couchdb/local.d/ccnq3 does not work.
COUCHDB_CONFIG=/etc/couchdb/local.ini

usage () {
  cat - <<USAGE
Usage:
  sudo $0         Creates manager host: overwrites local CouchDB configuration
  CDB_URI=uri $0  Creates manager host: uses existing CouchDB database
  $0 URI          Creates non-manager host
USAGE
}

if [ "x$1" == "x-h" ]; then
  shift
  usage
  exit
fi

if [ ! -d "${SRC}" ]; then
  echo "ERROR: You must install the ccnq3 package before calling this script."
  exit 1
fi

cd "$SRC"

if [ -e "${CONF}" ]; then
  echo "ERROR: $CONF already exists."
  exit 1
fi

HOSTNAME=`hostname`

configure_couchdb () {
  echo "Re-configuring CouchDB on local host ${HOSTNAME}"

  # Using 128 or higher does not work.
  ADMIN_PASSWORD=`openssl rand 64 -hex`

  # Install default config file
  /etc/init.d/couchdb stop
  # Double-enforce (currently having issues with this).
  killall couchdb beam.smp heart || echo OK

  tee "${COUCHDB_CONFIG}" <<EOT >/dev/null
[httpd]
port = 5984
bind_address = ::
WWW-Authenticate = Basic realm="couchdb"

[couch_httpd_auth]
require_valid_user = true

[log]
level = error

[admins]
admin = ${ADMIN_PASSWORD}
EOT
  chown couchdb.couchdb "${COUCHDB_CONFIG}"

  /etc/init.d/couchdb start

  CDB_URI="http://admin:${ADMIN_PASSWORD}@${HOSTNAME}:5984"
}

if [ "x$1" == "x" ]; then

  # Manager installation
  if [ "x$CDB_URI" == "x" ]; then
    configure_couchdb
  fi

  echo "Creating ${CONF}"
  tee "${CONF}" <<JSON >/dev/null
{
  "_id": "host:${HOSTNAME}",
  "type": "host",
  "host": "${HOSTNAME}",
  "admin": {
    "couchdb_uri": "${CDB_URI}"
  , "system": true
  }
, "applications": [
    "applications/usercode"
  , "applications/provisioning"
  , "applications/roles"
  , "applications/host"
  , "applications/portal"
  , "applications/inbox"
  , "public"
  , "applications/web"
  ]
, "source": "${SRC}"
, "account": ""
}
JSON
  # applications/usercode: creates the usercode database: must be first since all others depend on it
  # applications/provisioning: creates the provisioning database: must be second
  # applications/roles: updates the _users databases: must be third
  # applications/portal: portal pre-requires host

else

  # Non-manager installation
  echo "Retrieving ${CONF}"
  curl -o "${CONF}" "$1"

fi

chown "$USER" "$CONF"

echo "Update"
npm run-script updates

# Do not restart just yet.
echo "Bootstrap local host"
npm run-script bootstrap

echo "Restart"
npm restart

echo "Installation done."
echo
echo "Master interface: ${CDB_URI}/_utils/"
