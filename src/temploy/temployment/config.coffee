Fs = require('fs')
YAMLConfig = require('js-yaml')

class Config

  constructor: (directory) ->
    @filepath = "#{directory}/.temploy.yml"

  exists: ->
    Fs.existsSync(@filepath)

  # TODO: Extract ngrok args verification to Ngrok?
  isValid: ->
    @start? and @stop? and /-log=stdout/.test(@ngrokCommand)

  load: ->
    config = YAMLConfig.load(Fs.readFileSync(@filepath, 'utf-8'))
    @start = config.start
    @stop = config.stop
    @ngrokCommand = config.ngrok_command or 'ngrok -log=stdout 3000'
    @ttl = (config.ttl or 30) * 60 * 1000


module.exports = Config
