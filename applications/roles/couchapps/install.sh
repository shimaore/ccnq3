
echo "Installing rules into _users."
coffee -c users.coffee
couchapp push users.js http://admin:`cat ~/admin.txt`@127.0.0.1:5984/_users

echo "Creating CouchDB databases."
curl -X PUT http://admin:`cat ~/admin.txt`@127.0.0.1:5984/databases

echo "Installing rules into databases."
coffee -c databases.js
couchapp push databases.js http://admin:`cat ~/admin.txt`@127.0.0.1:5984/databases

