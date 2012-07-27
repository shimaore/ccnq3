@name = 'process'
@description = 'Provide information on the monitor process itself'

@get = (cb) ->
  cb null,
    memoryUsage: process.memoryUsage()
    arch: process.arch
    platform: process.platform
    uptime: process.uptime()
