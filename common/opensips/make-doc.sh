#!/bin/sh
for f in fragments/*.cfg; do
  egrep '^# Group:|^# Required|^ Status:|^# Name:|^# Description:|^# Note:' $f | sed -e 's/^# //';
  echo -n 'Routes: '; grep 'route\[' $f | wc -l;
  grep 'route\[' $f | sed -e 's/^/  /' | sed -e 's/\].*$/]/'
  echo
done > doc.txt
# Inside a group, only one module may be selected.
