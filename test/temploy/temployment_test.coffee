require '../test_helper'
Q = require('q')
Fs = require('fs')
Config = require('../../src/temploy/temployment/config')
Ngrok = require('../../src/temploy/temployment/ngrok')
exec = require('../../src/temploy/temployment/process').exec
Temployment = require('../../src/temploy/temployment')

describe 'Temployment', ->
  beforeEach ->
    @temployment = new Temployment('p0deje/hubot-temploy-example', 4)

  afterEach (done) ->
    exec('rm -rf /tmp/hubot').then -> done()

  describe '#id', ->
    it 'returns pull request identifier', ->
      expect(@temployment.id).to.eql('p0deje/hubot-temploy-example#4')

  describe '#start()', ->
    @timeout(10000)

    it 'clones repository', ->
      sinon.spy(@temployment, 'cloneRepository')
      @temployment.start().then =>
        expect(@temployment.cloneRepository).to.be.called

    it 'starts temployment', ->
      sinon.spy(@temployment, 'startTemployment')
      @temployment.start().then =>
        expect(@temployment.startTemployment).to.be.called

    it 'starts ngrok', ->
      sinon.spy(@temployment, 'startNgrok')
      @temployment.start().then =>
        expect(@temployment.startNgrok).to.be.called

    it 'saves ngrok URL', ->
      @temployment.start().then =>
        expect(@temployment.url).to.match(/https?:\/\/\w+\.ngrok\.com/)

    context 'when error occurs', ->
      context 'during repository clone', ->
        beforeEach ->
          @temployment = new Temployment('blah/blah', 1)
          sinon.stub @temployment, 'cleanRepository'

        it 'propagates error', ->
          @temployment.start().catch (error) ->
            # On Mac, tar exits with 1.
            # On Linux, tar exits with 2.
            expect(error.message).to.match(/^`tar fxz app.tar.gz --strip-components 1` failed with code (1|2)$/)

        it 'cleans repository', ->
          @temployment.start().catch =>
            expect(@temployment.cleanRepository).to.be.called

      context 'because repository is misconfigured', ->
        beforeEach ->
          sinon.stub @temployment, 'configuredForTemployment', -> false
          sinon.stub @temployment, 'cleanRepository'

        it 'propagates error', ->
          @temployment.start().catch (error) ->
            expect(error.message).to.eql('Repository is not configured properly')

        it 'cleans repository', ->
          @temployment.start().catch =>
            expect(@temployment.cleanRepository).to.be.called

      context 'during temployment start', ->
        beforeEach ->
          sinon.stub @temployment, 'startTemployment', ->
            deferred = Q.defer()
            setTimeout ->
              deferred.reject new Error('Failed to temploy.')
            , 500
            deferred.promise
          sinon.stub @temployment, 'stop'
          sinon.stub @temployment, 'cleanRepository'

        it 'propagates error', ->
          @temployment.start().catch (error) ->
            expect(error.message).to.eql('Failed to temploy.')

        it 'stops temployment', ->
          @temployment.start().catch =>
            expect(@temployment.stop).to.be.called

        it 'cleans repository', ->
          @temployment.start().catch =>
            expect(@temployment.cleanRepository).to.be.called

      context 'during ngrok start', ->
        beforeEach ->
          sinon.stub @temployment, 'startNgrok', ->
            deferred = Q.defer()
            setTimeout ->
              deferred.reject new Error('Failed to start ngrok.')
            , 500
            deferred.promise
          sinon.stub @temployment, 'stop'
          sinon.stub @temployment, 'cleanRepository'

        it 'propagates error', ->
          @temployment.start().catch (error) ->
            expect(error.message).to.eql('Failed to start ngrok.')

        it 'stops temployment', ->
          @temployment.start().catch =>
            expect(@temployment.stop).to.be.called

        it 'cleans repository', ->
          @temployment.start().catch =>
            expect(@temployment.cleanRepository).to.be.called

  describe '#stop()', ->
    beforeEach ->
      @temployment.config = {start: 'echo', stop: 'echo'}
      @temployment.repo = {directory: '/tmp', clean: sinon.stub()}

    it 'kills ngrok', ->
      sinon.spy(@temployment, 'stopNgrok')
      @temployment.stop().then =>
        expect(@temployment.stopNgrok).to.be.called

    it 'calls temployment stop command', ->
      sinon.spy(@temployment, 'stopTemployment')
      @temployment.stop().then =>
        expect(@temployment.stopTemployment).to.be.called

    it 'performs cleanup', ->
      sinon.spy(@temployment, 'cleanRepository')
      @temployment.stop().then =>
        expect(@temployment.cleanRepository).to.be.called

  describe '#isStarting()', ->
    it 'returns false if temployment is not starting', ->
      expect(@temployment.isStarting()).to.eql(false)

    it 'returns true if temployment is starting', ->
      @temployment.state = 'starting'
      expect(@temployment.isStarting()).to.eql(true)

  describe '#isStarted()', ->
    it 'returns false if temployment is started', ->
      expect(@temployment.isStarted()).to.eql(false)

    it 'returns true if temployment is started', ->
      @temployment.state = 'started'
      expect(@temployment.isStarted()).to.eql(true)

  describe '#shouldBeStopped()', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()
      @temployment.config = {ttl: 1000}
      @temployment.ngrok = {lastRequestTime: new Date()}
      @temployment.state = 'started'

    afterEach ->
      @clock.restore()

    it 'returns false if temployment is not started', ->
      @temployment.state = 'stopping'
      @clock.tick(1001)
      expect(@temployment.shouldBeStopped()).to.eql(false)

    it 'returns false if last request was made less than time-to-live ago', ->
      @clock.tick(999)
      expect(@temployment.shouldBeStopped()).to.eql(false)

    it 'returns false if last request was made time-to-live ago', ->
      @clock.tick(1000)
      expect(@temployment.shouldBeStopped()).to.eql(false)

    it 'returns true if last request was made more than time-to-live ago', ->
      @clock.tick(1001)
      expect(@temployment.shouldBeStopped()).to.eql(true)

  describe '#cloneRepository()', ->
    beforeEach ->
      @temployment.repo = {clone: sinon.spy()}

    it 'changes temployment state to started', ->
      @temployment.cloneRepository()
      expect(@temployment.state).to.eql('starting')

    it 'clones repository', ->
      @temployment.cloneRepository()
      expect(@temployment.repo.clone).to.be.called

  describe '#cleanRepository()', ->
    it 'cleans repository', ->
      @temployment.repo = {clean: sinon.spy()}
      @temployment.cleanRepository()
      expect(@temployment.repo.clean).to.be.called

  describe '#configuredForTemployment()', ->
    beforeEach ->
      @temployment.config = new Config('/tmp')

    it 'returns false if config does not exist', ->
      sinon.stub(@temployment.config, 'exists', -> false)
      sinon.stub(@temployment.config, 'isValid', -> true)
      expect(@temployment.configuredForTemployment()).to.eql(false)

    it 'returns false if config is not valid', ->
      sinon.stub(@temployment.config, 'exists', -> true)
      sinon.stub(@temployment.config, 'load')
      sinon.stub(@temployment.config, 'isValid', -> false)
      expect(@temployment.configuredForTemployment()).to.eql(false)

    it 'returns true if config is valid', ->
      sinon.stub(@temployment.config, 'exists', -> true)
      sinon.stub(@temployment.config, 'isValid', -> true)
      sinon.stub(@temployment.config, 'load')
      expect(@temployment.configuredForTemployment()).to.eql(true)

    it 'loads config', ->
      sinon.stub(@temployment.config, 'exists', -> true)
      sinon.stub(@temployment.config, 'isValid', -> true)
      sinon.stub(@temployment.config, 'load')
      @temployment.configuredForTemployment()
      expect(@temployment.config.load).to.be.called

  describe '#startTemployment()', ->
    beforeEach ->
      @temployment.config = {start: 'touch startTemployment'}
      @temployment.repo = {directory: '/tmp'}

    it 'executes start command', ->
      @temployment.startTemployment().then =>
        expect(Fs.existsSync('/tmp/startTemployment')).to.eql(true)

    it 'changes temployment state to started', ->
      @temployment.startTemployment().then =>
        expect(@temployment.state).to.eql('started')

  describe '#stopTemployment()', ->
    beforeEach ->
      @temployment.config = {stop: 'touch stopTemployment'}
      @temployment.repo = {directory: '/tmp'}

    it 'executes stop command', ->
      @temployment.stopTemployment().then ->
        expect(Fs.existsSync('/tmp/stopTemployment')).to.eql(true)

    it 'changes temployment state to stopped', ->
      @temployment.stopTemployment().then =>
        expect(@temployment.state).to.eql('stopped')

  describe '#startNgrok()', ->
    it 'starts ngrok', ->
      @temployment.ngrok = new Ngrok('ngrok -log=stdout 3000', '/tmp')
      sinon.spy(@temployment.ngrok, 'start')
      @temployment.startNgrok().then =>
        expect(@temployment.ngrok.start).to.be.called

  describe '#stopNgrok()', ->
    beforeEach ->
      @temployment.ngrok = new Ngrok('ngrok -log=stdout 3000', '/tmp')
      sinon.spy(@temployment.ngrok, 'stop')

    it 'stops ngrok', ->
      @temployment.state = 'started'
      @temployment.startNgrok().then =>
        @temployment.stopNgrok()
        expect(@temployment.ngrok.stop).to.be.called

    it 'changes temployment state to stopping', ->
      @temployment.state = 'started'
      @temployment.startNgrok().then =>
        @temployment.stopNgrok()
        expect(@temployment.state).to.eql('stopping')

    it 'does nothing if temployment is not started', ->
      @temployment.startNgrok().then =>
        @temployment.stopNgrok()
        expect(@temployment.ngrok.stop).not.to.be.called
