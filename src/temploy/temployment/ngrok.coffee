Q = require('q')
exec = require('./process').exec

class Ngrok

  constructor: (command, directory) ->
    @command = command
    @directory = directory

  start: ->
    deferred = Q.defer()

    exec(@command, cwd: @directory)
      .progress (child) =>
        @process = child
        child.stdout.on 'data', (data) =>
          if data.toString().indexOf('Read message {"Type":"ReqProxy","Payload":{}}') != -1
            @lastRequestTime = new Date()
        child.stdout.on 'data', (data) ->
          if match = data.toString().match(/Tunnel established at (.+)/)
            deferred.resolve(match[1])
      .catch (error) ->
        deferred.reject(error)

    deferred.promise

  stop: ->
    @process.kill('SIGHUP') if @process?


module.exports = Ngrok
