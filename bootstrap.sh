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

if [ "x$1" == "x" ]; then

  # Manager installation
  if [ "x$CDB_URI" == "x" ]; then
    echo "ERROR: You must provide CDB_URI."
    exit 1
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

echo "Update"
npm run-script updates

# Do not restart just yet.
echo "Bootstrap local host"
npm run-script bootstrap

echo "Restart"
npm start

echo "Installation done."
echo
echo "Master interface: ${CDB_URI}/_utils/"
