require '../../test_helper'
Fs = require('fs')
Temp = require('temp').track()
Config = require('../../../src/temploy/temployment/config')

describe 'Config', ->
  createConfig = (body = null) ->
    body or= """
      start: echo
      stop: echo
    """
    dir = Temp.mkdirSync()
    Fs.writeFileSync("#{dir}/.temploy.yml", body, 'utf-8')
    dir

  describe '#exists()', ->
    it 'returns false if config file is absent', ->
      config = new Config('/tmp')
      expect(config.exists()).to.eql(false)

    it 'returns true if config file is present', ->
      config = new Config(createConfig())
      expect(config.exists()).to.eql(true)

  describe '#isValid()', ->
    it 'returns true if everything is correct', ->
      config = new Config(createConfig())
      config.load()
      expect(config.isValid()).to.eql(true)

    it 'returns false if start command is absent', ->
      config_path = createConfig 'stop: echo'
      config = new Config(config_path)
      config.load()
      expect(config.isValid()).to.eql(false)

    it 'returns false if stop command is absent', ->
      config_path = createConfig 'start: echo'
      config = new Config(config_path)
      config.load()
      expect(config.isValid()).to.eql(false)

    it 'returns false if ngrok command misses stdout logging', ->
      config_path = createConfig """
        start: echo
        stop: echo
        ngrok_command: ngrok 3000
      """
      config = new Config(config_path)
      config.load()
      expect(config.isValid()).to.eql(false)

  describe '#ngrokCommand', ->
    it 'runs on 3000 port by default', ->
      config = new Config(createConfig())
      config.load()
      expect(config.ngrokCommand).to.eql('ngrok -log=stdout 3000')

  describe '#ttl', ->
    it 'defaults to half an hour', ->
      config = new Config(createConfig())
      config.load()
      expect(config.ttl).to.eql(30 * 60 * 1000)

    it 'can be changed with number of minutes', ->
      config_path = createConfig """
        start: echo
        stop: echo
        ttl: 10
      """
      config = new Config(config_path)
      config.load()
      expect(config.ttl).to.eql(10 * 60 * 1000)
