# hubot-temploy [![Build Status](https://travis-ci.org/p0deje/hubot-temploy.svg)](https://travis-ci.org/p0deje/hubot-temploy) [![npm version](https://badge.fury.io/js/hubot-temploy.svg)](http://badge.fury.io/js/hubot-temploy)

[Hubot](https://hubot.github.com/) script to temporarily deploy pull requests.

# Install

Just add `hubot-temploy` to your `package.json` and `external-scripts.json`.

You might also need to install [ngrok](https://ngrok.com/) if you plan to deploy application locally.

# Commands

* `hubot temploys` - list of temployed pull requests
* `hubot temploy start owner/repo#1` - start temployment of pull request #1 for repository owner/repo
* `hubot temploy stop owner/repo#1` - stop temployment of pull request #1 for repository owner/repo

# Usage

First of all, you need to create `.temploy.yml` configuration file. It should contain `start` and `stop` commands at least:

```yaml
start: script/hubot_temploy_start.sh
stop: script/hubot_temploy_stop.sh
```

The start script should do everything necessary for your server to be running (let's pretend you have rails application) and spawn application in the background:

```bash
#!/bin/bash
cp config/database.yml.example config/database.yml
bundle install --path ~/.bundle
bundle exec rake db:setup
bundle exec rake assets:precompile RAILS_ENV=development
bundle exec rails s -d
```

Now, you can tell hubot to temploy your application pull request:

```
hubot temploy start owner/repo#1
```

_where `owner/repo` is the path to your Github repository and `1` is your pull request number_

After the script is executed, `hubot-temploy` will do the following:

* start [ngrok](https://ngrok.com/) (by default, on port 3000) and respond with exposed server URL
* schedule deployment stopping (by default, in 30 minutes)

Temployment stopping is done using `stop` script from configuration file (in this case it just kills rails process):

```bash
#!/bin/bash
kill $(ps ax | grep '[r]ails s' | awk '{print $1}')
```

It is also possible to force temployment stop:

```
hubot temploy stop owner/repo#1
```

You can also take a look at [hubot-temploy-example](https://github.com/p0deje/hubot-temploy-example) for a minimal working repository.

Of course, both examples are very simple and do not support parallel temployments (because ports/database are the same), so you might want to find a way to isolate each environment. One of the simplest solutions is to use Vagrant, create new virtual machine in start script and delete it in stop script.

# Configuration

You can also change a couple of configuration options:

```yaml
# .temploy.yml
ngrok_command: vagrant ssh -c "ngrok -log=stdout 3000" # change ngrok command to use (note that "-log=stdout" is mandatory)
ttl: 60 # change time until temployment is stopped to 1 hour
```

# TODO

1. Make tests less flaky (remove `sort -r` from `npm test`).
2. Think about making it work on Heroku.
3. Smarter temployment stop instead of "time to live": e.g. automatically stop if there were no requests within 10 minutes.
4. Support [hubot-redis-brain](https://github.com/hubot-scripts/hubot-redis-brain).
