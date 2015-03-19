require '../../test_helper'
http = require('http')
Ngrok = require('../../../src/temploy/temployment/ngrok')

describe 'Ngrok', ->
  before (done) ->
    port = 9876
    @server = http.createServer (_, response) ->
      response.writeHead(200, 'Content-Type': 'text/plain')
      response.end('okay')
    @server.listen(port, done)
    @ngrok = new Ngrok("ngrok -log=stdout #{port}", '/tmp')

  after ->
    @server.close()

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

  describe '#lastRequestTime', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()

    afterEach ->
      @clock.restore()

    it 'returns start time when no requests were made', ->
      @ngrok.start().then =>
        expect(@ngrok.lastRequestTime).to.eql(new Date())

    it 'is only updated on new requests', ->
      @ngrok.start().then =>
        now = new Date()
        @clock.tick(1000)
        expect(@ngrok.lastRequestTime).to.eql(now)

    it 'returns time of last request', (done) ->
      @ngrok.start().then (url) =>
        @clock.tick(1000)
        url = url.match(/\w+\.ngrok\.com/)[0]
        http.get host: url, (response) =>
          response.on 'data', (_) =>
            # 'end' is not emitted unless we have on('data')
          response.once 'end', =>
            expect(@ngrok.lastRequestTime).to.eql(new Date())
            done()
