#!/usr/bin/env coffee
# make.coffee -- merge OpenSIPS configuration fragments
# Copyright (C) 2009,2011  Stephane Alnet
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

fs = require 'fs'
params = {}

for _ in process.ARGV.slice 3
  do (_) ->
    data = JSON.parse fs.readFileSync _
    params[k] = data[k] for own k of data

require('./compiler') params
