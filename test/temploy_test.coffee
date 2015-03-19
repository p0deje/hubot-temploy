require './test_helper'
get = require('http').get
Robot = require('hubot/src/robot')
TextMessage = require('hubot/src/message').TextMessage
exec = require('../src/temploy/temployment/process').exec

describe 'hubot-temploy', ->
  @timeout(10000)

  beforeEach (done) ->
    @robot = new Robot(null, 'mock-adapter', false, 'hubot')
    @adapter = @robot.adapter
    @user = @robot.brain.userForId('1', name: 'test', room: '#test')
    @adapter.once 'connected', =>
      require('../index')(@robot)
      done()
    @robot.run()

  afterEach ->
    @robot.shutdown()
    process.removeAllListeners('uncaughtException')

  describe 'help', ->
    it 'tells about temploys command', ->
      expect(@robot.helpCommands()).to.include('hubot temploys - List of temployed pull requests')

    it 'tells about temploy start command', ->
      expect(@robot.helpCommands()).to.include('hubot temploy start owner/repo#1 - Start temployment of pull request #1 for repository owner/repo')

    it 'tells about temploy stop command', ->
      expect(@robot.helpCommands()).to.include('hubot temploy stop owner/repo#1 - Stop temployment of pull request #1 for repository owner/repo')

  describe 'temploys', ->
    it 'tells when there are no temployments', (done) ->
      @adapter.once 'send', (_, strings) ->
        expect(strings[0]).to.eql('No pull requests are temployed at the moment.')
        done()
      @adapter.receive new TextMessage(@user, 'hubot temploys')

    it 'tells about starting temployments', (done) ->
      @adapter.once 'send', (_, strings) =>
        # Give bot some time to start temployment.
        setTimeout =>
          @adapter.once 'send', (_, strings) ->
            expect(strings[0]).to.eql('p0deje/hubot-temploy-example#5 - starting.')
            done()
          @adapter.receive new TextMessage(@user, 'hubot temploys')
        , 200
      @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#5')

    it 'tells about started temployments', (done) ->
      @adapter.once 'reply', (_, strings) =>
        @adapter.once 'send', (_, strings) ->
          expect(strings[0]).to.match(/p0deje\/hubot-temploy-example#4 - temployed to https?:\/\/\w+\.ngrok\.com\./)
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploys')
      @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

    it 'does not tell about stopped temployment', (done) ->
      @adapter.once 'reply', (_, strings) =>
        @adapter.once 'reply', (_, strings) =>
          @adapter.once 'send', (_, strings) ->
            expect(strings[0]).to.eql('No pull requests are temployed at the moment.')
            done()
          @adapter.receive new TextMessage(@user, 'hubot temploys')
        @adapter.receive new TextMessage(@user, 'hubot temploy stop p0deje/hubot-temploy-example#4')
      @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

  describe 'temploy start', ->
    context 'when temployment cannot be started', ->
      it 'tells when temployment is already started', (done) ->
        @adapter.once 'reply', (_, strings) =>
          @adapter.once 'send', (_, strings) ->
            expect(strings[0]).to.eql('Well, p0deje/hubot-temploy-example#4 is started.')
            done()
          @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

      it 'tells when temployment start has failed', (done) ->
        @adapter.once 'reply', (_, strings) ->
          expect(strings[0]).to.eql('Failed to temploy p0deje/hubot-temploy-example#7: Repository is not configured properly.')
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#7')

      it 'removes temployment when start has failed', (done) ->
        @adapter.once 'reply', (_, strings) =>
          @adapter.once 'send', (_, strings) ->
            expect(strings[0]).to.eql('No pull requests are temployed at the moment.')
            done()
          @adapter.receive new TextMessage(@user, 'hubot temploys')
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#7')

    context 'when temployment can be started', ->
      it 'tells that it has started temploying', (done) ->
        @adapter.once 'send', (_, strings) ->
          expect(strings[0]).to.eql('Temploying p0deje/hubot-temploy-example#4. Hold on.')
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

      it 'tells when temployment has started successfully', (done) ->
        @adapter.once 'reply', (_, strings) ->
          expect(strings[0]).to.match(/Temployed p0deje\/hubot-temploy-example#4 to https?:\/\/\w+\.ngrok\.com\./)
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

      it 'successfully temploys app', (done) ->
        @adapter.once 'reply', (_, strings) ->
          url = strings[0].match(/\w+\.ngrok\.com/)[0]
          get host: url, (response) ->
            body = ''
            response.on 'data', (chunk) -> body += chunk
            response.once 'end', ->
              expect(body).to.include('Simple hubot-temploy example app')
              done()
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

      context 'after time-to-live since last request', ->
        before ->
          @clock = sinon.useFakeTimers()

        it 'stops temployment ', (done) ->
          @adapter.once 'reply', (_, strings) =>
            @clock.tick(61 * 1000)
            @adapter.once 'send', (_, strings) =>
              expect(strings[0]).to.eql('No pull requests are temployed at the moment.')
              done()
            @clock.restore()
            # Give bot some time to stop temployment.
            setTimeout =>
              @adapter.receive new TextMessage(@user, 'hubot temploys')
            , 500
          @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#6')

  describe 'temploy stop', ->
    context 'when temployment cannot be stopped', ->
      it 'tells that temployment is not started', (done) ->
        @adapter.once 'send', (_, strings) ->
          expect(strings[0]).to.eql('Looks like it has not been temployed yet.')
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploy stop p0deje/hubot-temploy-example#4')

      it 'tells that temployment is starting', (done) ->
        @adapter.once 'send', (_, strings) =>
          # Give bot some time to start temployment.
          setTimeout =>
            @adapter.once 'send', (_, strings) ->
              expect(strings[0]).to.eql("Looks like p0deje/hubot-temploy-example#5 is temploying now. You can't stop it till it's done.")
              done()
            @adapter.receive new TextMessage(@user, 'hubot temploy stop p0deje/hubot-temploy-example#5')
          , 200
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#5')

    context 'when temployment can be stopped', ->
      beforeEach (done) ->
        @adapter.once 'reply', (_, strings) =>
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploy start p0deje/hubot-temploy-example#4')

      it 'tells that it has started temployment stop', (done) ->
        @adapter.once 'send', (_, strings) =>
          expect(strings[0]).to.eql('Stopping p0deje/hubot-temploy-example#4. Hold on.')
          @adapter.once 'reply', (_, strings) -> done()
        @adapter.receive new TextMessage(@user, 'hubot temploy stop p0deje/hubot-temploy-example#4')

      it 'tells that temployment has stopped successfully', (done) ->
        @adapter.once 'reply', (_, strings) ->
          expect(strings[0]).to.eql('Temployment p0deje/hubot-temploy-example#4 is stopped.')
          done()
        @adapter.receive new TextMessage(@user, 'hubot temploy stop p0deje/hubot-temploy-example#4')

      it 'tells that temployment stop has failed', (done) ->
        exec('rm -rf /tmp/hubot').then =>
          @adapter.once 'reply', (_, strings) ->
            expect(strings[0]).to.eql('Failed to stop temployment p0deje/hubot-temploy-example#4: spawn ENOENT.')
            done()
          @adapter.receive new TextMessage(@user, 'hubot temploy stop p0deje/hubot-temploy-example#4')
