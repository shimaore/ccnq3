
echo "Installing rules into host."
coffee -c host.coffee
couchapp push host.js http://admin:`cat ~/admin.txt`@127.0.0.1:5984/provisioning

curl -u admin:`cat ~/admin.txt` --basic \
    --request PUT \
    --header 'Content-Type: application/json' \
    --data @- \
    'http://127.0.0.1:5984/log/_security' <<'JSON'
{
  "admins": {
    "names":[],
    "roles":["log_admin"]
  },
  "readers": {
    "names":[],
    "roles":["log_reader"]
  }
}
JSON


