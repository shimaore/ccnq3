#!/usr/bin/env bash

set -e
export LANG=
NAME="`ccnq3 'get name'`"
USER=$NAME

HOSTNAME="`ccnq3 'get hostname'`"

# ----------- CouchDB ---------- #

COUCHDB_CONFIG=/etc/couchdb/local.ini
CDB_DIR=/var/lib/couchdb/$NAME

if egrep -q '^admin' ${COUCHDB_CONFIG}; then
  echo "CouchDB already configured."
else
  echo "Re-configuring CouchDB"

  # Using 128 or higher does not work.
  ADMIN_PASSWORD=`openssl rand 64 -hex`

  # Install default config file
  /etc/init.d/couchdb stop
  # Double-enforce (currently having issues with this).
  killall couchdb beam.smp heart || echo OK

  mkdir -p $CDB_DIR
  chmod 0755 $CDB_DIR
  chown couchdb.couchdb $CDB_DIR

  # Apparently using /etc/couchdb/local.d/ccnq3 does not work.
  cp "`ccnq3 'get config source'`/manager.ini" "${COUCHDB_CONFIG}"
  sed -i -e "s/CDB_DIR/${CDB_DIR}" "${COUCHDB_CONFIG}"
  sed -i -e "s/ADMIN_PASSWORD/${ADMIN_PASSWORD}" "${COUCHDB_CONFIG}"
  chown couchdb.couchdb "${COUCHDB_CONFIG}"

  su -s /bin/sh -c "ccnq3 'set admin uri' 'http://admin:${ADMIN_PASSWORD}@${HOSTNAME}:5984'" $USER

  /etc/init.d/couchdb start

fi

# -------- RabbitMQ ---------- #

RABBITMQ_CONFIG=/etc/rabbitmq/rabbitmq.config
if grep -q 'ssl_listeners' ${RABBITMQ_CONFIG}; then
  echo 'RabbitMQ already configured.'
else
  # Delete the default `guest` user.
  rabbitmqctl delete_user guest

  # Add an `admin` user back in
  rabbitmqctl add_user admin "${ADMIN_PASSWORD}"

  cp "`ccnq3 'get config source'`/rabbitmq.config" ${RABBITMQ_CONFIG}

  ccnq3 'set admin amqp' "amqp://admin:${ADMIN_PASSWORD}@${HOSTNAME}"

fi
