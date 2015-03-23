Q = require('q')
Config = require('./temployment/config')
Ngrok = require('./temployment/ngrok')
Repository = require('./temployment/repository')
exec = require('./temployment/process').exec

class Temployment

  constructor: (repository, pullRequestId) ->
    @id = "#{repository}##{pullRequestId}"
    @repo = new Repository(repository, pullRequestId)

  # Generic function to start temployment, which covers
  # the whole process from pull request cloning to scheduling
  # its stop, catching any possible errors and doing cleanup.
  start: ->
    @cloneRepository()
      .then =>
        if @configuredForTemployment()
          @startTemployment()
            .then =>
              @startNgrok()
                .then (url) => @url = url
            .catch (error) =>
              @stop()
              throw error
        else
          throw new Error('Repository is not configured properly')
      .catch (error) =>
        @cleanRepository()
        throw error

  # Generic function to stop temployment, which covers
  # the whole process from stopping exposing tool to cleanup.
  stop: ->
    @stopNgrok()
    @stopTemployment()
      .then => @cleanRepository()

  isStarting: ->
    @state == 'starting'

  isStarted: ->
    @state == 'started'

  shouldBeStopped: ->
    @isStarted() and new Date() > (@ngrok.lastRequestTime.getTime() + @config.ttl)

  # private

  cloneRepository: ->
    @state = 'starting'
    @repo.clone()

  cleanRepository: ->
    @repo.clean()

  configuredForTemployment: ->
    @config or= new Config(@repo.directory)
    if @config.exists()
      @config.load()
      @config.isValid()
    else
      false

  startTemployment: ->
    # TODO Some processes may get stalled when certain stdio
    #   is set to 'pipe' (default), that's why we force 'ignore'.
    #   For example: "psql -f dump.sql" (stalls with stderr).
    #   Need to investigate the problem and report a bug.
    exec(@config.start, cwd: @repo.directory, stdio: 'ignore')
      .then => @state = 'started'

  stopTemployment: ->
    exec(@config.stop, cwd: @repo.directory)
      .then => @state = 'stopped'

  startNgrok: ->
    @ngrok or= new Ngrok(@config.ngrokCommand, @repo.directory)
    @ngrok.start()

  stopNgrok: ->
    if @isStarted()
      @state = 'stopping'
      @ngrok.stop()


module.exports = Temployment
