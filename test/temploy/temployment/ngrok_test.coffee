require '../../test_helper'
Ngrok = require('../../../src/temploy/temployment/ngrok')

describe 'Ngrok', ->
  before ->
    @ngrok = new Ngrok('ngrok -log=stdout 3000', '/tmp')

  describe '#start()', ->
    it 'starts ngrok process', ->
      @ngrok.start().then  =>
        expect(@ngrok.process.killed).to.eql(false)

    it 'resolves promise with server URL', ->
      @ngrok.start().then (url) ->
        expect(url).to.match(/https?:\/\/\w+\.ngrok\.com/)

  describe '#stop()', ->
    it 'stops ngrok process', ->
      @ngrok.start().then =>
        @ngrok.stop()
        expect(@ngrok.process.killed).to.eql(true)
