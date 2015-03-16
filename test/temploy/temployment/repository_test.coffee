require '../../test_helper'
Fs = require('fs')
Repository = require('../../../src/temploy/temployment/repository')
exec = require('../../../src/temploy/temployment/process').exec

describe 'Repository', ->
  beforeEach ->
    @repository = new Repository('p0deje/watirsome', 1)

  after (done) ->
    exec('rm -rf /tmp/hubot').then -> done()

  describe '#directory', ->
    it 'is temporary directory of each pull request', ->
      expect(@repository.directory).to.eql('/tmp/hubot/temploy/p0deje/watirsome/1')

  describe '#clean()', ->
    it 'removes pull request directory', (done) ->
      exec("mkdir -p #{@repository.directory}").then =>
        @repository.clean().then =>
          expect(Fs.existsSync(@repository.directory)).to.eql(false)
          done()

  describe '#clone()', ->
    @timeout(10000)

    it 'creates pull request directory', (done) ->
      @repository.clone().then =>
        expect(Fs.existsSync(@repository.directory)).to.eql(true)
        done()

    it 'clones pull request to directory', (done) ->
      @repository.clone().then =>
        expect(Fs.existsSync("#{@repository.directory}/watirsome.gemspec")).to.eql(true)
        done()

    it 'removes repository archive', (done) ->
      @repository.clone().then =>
        expect(Fs.existsSync("#{@repository.directory}/app.tar.gz")).to.eql(false)
        done()
