Q = require('q')
spawn = require('child_process').spawn

class Process

  @exec: (command, opts = {}) ->
    deferred = Q.defer()

    # We need to properly parse arguments passed in quotes:
    #   ngrok -log=stdout 3000           #=> ['ngrok', '-log=stdout', '3000']
    #   bash -c "ngrok -log=stdout 3000" #=> ['bash', '-c', 'ngrok -log=stdout 3000']
    args = command.split(/([^\s"']+)|['"](.+)['"]/)
                  .filter (arg) -> arg and arg.trim().length > 0

    cmd = args.shift()
    opts.env = process.env

    child = spawn(cmd, args, opts)

    process.nextTick ->
      deferred.notify(child)

    child.on 'error', deferred.reject
    child.on 'exit', (code) ->
      if code and code != 0
        deferred.reject new Error("`#{command}` failed with code #{code}")
      else
        deferred.resolve()

    deferred.promise


module.exports = Process
