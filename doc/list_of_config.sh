#!/bin/bash
for DIR in applications/; do
echo "# In $DIR"
rgrep '[^_]config\.' "${DIR}" | perl -p -e '@a = /(config\.[\w.]+)/g; $_ = join("\n",@a)."\n"' | sort -u
done
