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

export CDB_URI="http://admin:${ADMIN_PASSWORD}@${HOSTNAME}:5984"
exec su -s /bin/bash -c "${SRC}/bootstrap.sh" "${USER}"
