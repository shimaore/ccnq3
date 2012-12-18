#!/usr/bin/env bash
# (c) 2011 Stephane Alnet

set -e
export LANG=
NAME="`ccnq3 'get name'`"

# --------- CouchDB --------- #

COUCHDB_CONFIG=/etc/couchdb/local.ini
CDB_DIR=/var/lib/couchdb/$NAME
if grep -q '"party"-mode' ${COUCHDB_CONFIG}; then
  echo 'CouchDB already configured.'
else
  echo 'Re-configuring CouchDB.'

  /etc/init.d/couchdb stop
  # Double-enforce (currently having issues with this).
  killall couchdb beam.smp heart || echo OK

  mkdir -p $CDB_DIR
  chmod 0755 $CDB_DIR
  chown couchdb.couchdb $CDB_DIR

  # Apparently using /etc/couchdb/local.d/ccnq3 does not work.
  cp "`ccnq3 'get config source'`/client.ini" $COUCHDB_CONFIG
  sed -i -e "s/CDB_DIR/${CDB_DIR}/" $COUCHDB_CONFIG
  chown couchdb.couchdb "${COUCHDB_CONFIG}"

  /etc/init.d/couchdb start
fi
