#!/usr/bin/env bash

daemon -n "ccnq3_mail_confirmation" -r -o daemon.debug -- coffee agents/mail_confirmation.coffee
daemon -n "ccnq3_mail_password"     -r -o daemon.debug -- coffee agents/mail_password.coffee
daemon -n "ccnq3_portal"            -r -o daemon.debug -- coffee start_portal.coffee

