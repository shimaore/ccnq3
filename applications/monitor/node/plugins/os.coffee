@name = 'os'
@description = 'Provide information on the operating system'

os = require 'os'
fs = require 'fs'

@get = (cb) ->
  cb null,
    hostname: os.hostname()
    type: os.type()
    platform: os.platform()
    arch: os.arch()
    release: os.release()
    uptime: os.uptime()
    loadavg: os.loadavg()
    totalmem: os.totalmem()
    freemem: os.freemem()
    cpus: os.cpus()
    networkInterfaces: os.networkInterfaces()
    proc_version: fs.readFileSync '/proc/version', 'utf8'
