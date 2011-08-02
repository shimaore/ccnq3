#!/bin/bash
rgrep '[^_]config\.' applications/ private/ | perl -p -e '@a = /(config\.[\w.]+)/; $_ = join("\n",@a)."\n"' | sort -u
