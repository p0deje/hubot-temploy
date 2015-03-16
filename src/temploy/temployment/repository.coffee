exec = require('./process').exec

class Repository

  constructor: (@repository, @pullRequestId) ->
    @directory = "/tmp/hubot/temploy/#{@repository}/#{@pullRequestId}"
    @_archive = 'app.tar.gz'

  clean: ->
    exec("rm -rf #{@directory}")

  clone: ->
    exec("mkdir -p #{@directory}")
      .then => exec("curl #{@_curlArgs()}")
      .then => exec("tar fxz #{@_archive} --strip-components 1", cwd: @directory)
      .then => exec("rm -f #{@_archive}", cwd: @directory)

  # private

  _curlArgs: ->
    args = [
      '--silent'
      '--location'
      "https://api.github.com/repos/#{@repository}/tarball/pull/#{@pullRequestId}/head"
      '--output'
      "#{@directory}/#{@_archive}"
    ]

    if process.env.HUBOT_GITHUB_TOKEN?
      args = args.concat(['--user', "#{process.env.HUBOT_GITHUB_TOKEN}:x-oauth-basic"])

    args.join(' ')


module.exports = Repository
