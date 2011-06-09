
echo "Installing rules into _users."
coffee -c users.coffee
couchapp push users.js "${CDB_URI}/_users"

