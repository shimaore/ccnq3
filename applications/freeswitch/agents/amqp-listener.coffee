ccnq3 = require 'ccnq3'
process_changes = require './process-changes'

ccnq3.command.handler 'freeswitch', process_changes
