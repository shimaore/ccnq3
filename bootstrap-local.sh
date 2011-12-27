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

echo "Re-configuring CouchDB on local host ${HOSTNAME}"

# Install default config file
/etc/init.d/couchdb stop
# Double-enforce (currently having issues with this).
killall couchdb beam.smp heart || echo OK

tee "${COUCHDB_CONFIG}" <<EOT >/dev/null
[httpd]
port = 5984
bind_address = 127.0.0.1

[couch_httpd_auth]
require_valid_user = false

[log]
level = error

[admins]
EOT
chown couchdb.couchdb "${COUCHDB_CONFIG}"

/etc/init.d/couchdb start

export CDB_URI="http://127.0.0.1:5984"
exec su -s /bin/bash -c "${SRC}/bootstrap.sh $1" "${USER}"
