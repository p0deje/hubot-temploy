require '../../test_helper'
exec = require('../../../src/temploy/temployment/process').exec

describe 'Process', ->
  @timeout(5000)

  describe '.exec()', ->
    it 'resolves promise when process completes', (done) ->
      exec('env').then -> done()

    it 'rejects promise on error', (done) ->
      exec('blah').catch -> done()

    it 'rejects promise when process fails', (done) ->
      exec('grep').catch -> done()

    it 'properly parses string arguments', (done) ->
      exec('bash -c "echo 1"').then -> done()

    it 'allows to add callbacks ', (done) ->
      exec('echo').progress -> done()

    it 'uses process environment', (done) ->
      stdout = ''
      process.env.TEST = 1
      exec('env')
        .progress (child) ->
          child.stdout.on 'data', (data) ->
            stdout += data.toString()
        .then ->
          expect(stdout).to.match(/TEST=1/)
          done()

    it 'allows to pass arguments to child process', (done)  ->
      exec('pwd', cwd: '/usr').progress (child) ->
        child.stdout.on 'data', (data) ->
          expect(data.toString()).to.eql('/usr\n')
          done()
