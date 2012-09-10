#!/usr/bin/env bash

coffee -c js/*.coffee
cat js/jshash-2.2/sha1-min.js \
    js/jshash-2.2/md5-min.js  \
    js/jquery.js          \
    js/jquery-ui.js       \
    js/jquery.validate.js \
    js/jquery.datatables.js \
    js/jquery.couch.js    \
    js/jquery.deepjson.js \
    js/sammy.js           \
    js/sammy.title.js     \
    js/sammy.couch.js     \
    js/coffeekup.js       \
    js/EventEmitter.min.js \
    js/forms.js           \
    js/inbox.js           \
    js/milk.js            \
    menu/menu.js          \
    js/ccnq3.js           \
  > js/default.js

cat css/style.css         \
    css/jquery-ui.css     \
    css/datatables.css    \
    menu/menu.css         \
  > css/default.css
