
echo "Installing rules into _users."
coffee -c users.coffee
couchapp push users.js http://admin:`cat ~/admin.txt`@127.0.0.1:5984/_users

