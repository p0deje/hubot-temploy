# Description:
#   Temporarily deploys pull request.
#
# Configuration:
#   HUBOT_GITHUB_TOKEN - GitHub authentication token
#
# Commands:
#  hubot temploys - list of temployed pull requests
#  hubot temploy start owner/repo#1 - start temployment of pull request #1 for repository owner/repo
#  hubot temploy stop owner/repo#1 - stop temployment of pull request #1 for repository owner/repo
#
# Author:
#   p0deje
#
# Tags:
#   deploy
#
# URLs:
#   https://github.com/p0deje/hubot-temploy

module.exports = (robot) ->
  Temployment = require('./temploy/temployment')
  TemploymentCollection = require('./temploy/temployment_collection')
  temployments = new TemploymentCollection(robot.brain)


  robot.respond /temploys$/i, (msg) ->
    if temployments.isEmpty()
      msg.send 'No pull requests are temployed at the moment.'
    else
      reply = temployments
        .map (temployment) ->
          if temployment.isStarted()
            "#{temployment.id} - temployed to #{temployment.url}."
          else
            "#{temployment.id} - #{temployment.state}."
        .join("\n")
      msg.send reply


  robot.respond /temploy start ([0-9A-Za-z-_]+\/[0-9A-Za-z-_]+)#(\d+)$/i, (msg) ->
    [_, repository, pullRequestId] = msg.match
    temployment = new Temployment(repository, pullRequestId)

    if temployments.get(temployment.id)?
      temployment = temployments.get(temployment.id)
      return msg.send "Well, #{temployment.id} is #{temployment.state}."

    temployments.add(temployment)
    msg.send "Temploying #{temployment.id}. Hold on."
    temployment.start()
      .then ->
        temployment.schedule -> temployments.remove(temployment.id)
        msg.reply "Temployed #{temployment.id} to #{temployment.url}."
      .catch (error) ->
        temployments.remove(temployment.id)
        msg.reply "Failed to temploy #{temployment.id}: #{error.message}."


  robot.respond /temploy stop ([0-9A-Za-z-_]+\/[0-9A-Za-z-_]+)#(\d+)$/i, (msg) ->
    [_, repository, pullRequestId] = msg.match
    temployment = new Temployment(repository, pullRequestId)
    temployment = temployments.get(temployment.id)

    unless temployment?
      return msg.send "Looks like it has not been temployed yet."

    if temployment.isStarting()
      return msg.send "Looks like #{temployment.id} is temploying now. You can't stop it till it's done."

    msg.send "Stopping #{temployment.id}. Hold on."
    temployment.stop()
      .then ->
        temployments.remove(temployment.id)
        msg.reply "Temployment #{temployment.id} is stopped."
      .catch (error) ->
        msg.reply "Failed to stop temployment #{temployment.id}: #{error.message}."
