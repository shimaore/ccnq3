#!/usr/bin/env bash
# (c) 2011 Stephane Alnet

set -e
export LANG=
NAME="`ccnq3 'get name'`"
CONF="`ccnq3 'get config location'`"

if [ -z "${CONF}" ]; then
  echo "ERROR: You must install the $NAME package before calling this script."
  exit 1
fi

if [ -e "${CONF}" ]; then
  echo "ERROR: $CONF already exists."
  exit 1
fi

# --------- CouchDB --------- #

echo "Re-configuring CouchDB"

# Install default config file
/etc/init.d/couchdb stop
# Double-enforce (currently having issues with this).
killall couchdb beam.smp heart || echo OK

CDB_DIR=/var/lib/couchdb/$NAME
mkdir -p $CDB_DIR
chmod 0755 $CDB_DIR
chown couchdb.couchdb $CDB_DIR

# Apparently using /etc/couchdb/local.d/ccnq3 does not work.
COUCHDB_CONFIG=/etc/couchdb/local.ini
tee "${COUCHDB_CONFIG}" <<EOT >/dev/null
;
; A configuration file for a local-only, "party"-mode CouchDB instance.
;
[couchdb]
; Avoid issues with databases disappearing when CouchDB upgrades.
database_dir = ${CDB_DIR}
view_index_dir = ${CDB_DIR}

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

# ---------- RabbitMQ --------- #

# Not installed locally.
