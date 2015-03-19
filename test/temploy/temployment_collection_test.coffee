require '../test_helper'
Robot = require('hubot/src/robot')
Temployment = require('../../src/temploy/temployment')
TemploymentCollection = require('../../src/temploy/temployment_collection')

describe 'TemploymentCollection', ->
  beforeEach ->
    @brain = new Robot(null, 'mock-adapter', false, 'hubot').brain
    @temployments = new TemploymentCollection(@brain)
    @temployment = new Temployment('p0deje/hubot-temploy-example', 4)

  afterEach ->
    process.removeAllListeners('uncaughtException')

  describe '#isEmpty()', ->
    it 'returns true when there are no temployments', ->
      expect(@temployments.isEmpty()).to.eql(true)

    it 'returns false when there are temployments', ->
      @brain.set 'temployments', [@temployment]
      expect(@temployments.isEmpty()).to.eql(false)

  describe '#get()', ->
    it 'returns undefined when there are no temployment with id', ->
      @brain.set 'temployments', [@temployment]
      expect(@temployments.get('p0deje/hubot-temploy-example#7')).to.eql(undefined)

    it 'returns temployment by its id', ->
      @brain.set 'temployments', [@temployment]
      expect(@temployments.get(@temployment.id)).to.eql(@temployment)

  describe '#add()', ->
    it 'adds temployment to collection', ->
      @temployments.add(@temployment)
      expect(@brain.get('temployments').length).to.eql(1)

  describe '#remove()', ->
    it 'removes temployment from collection', ->
      @brain.set 'temployments', [@temployment]
      @temployments.remove(@temployment.id)
      expect(@brain.get('temployments').length).to.eql(0)

  describe '#map()', ->
    it 'maps over temployments', ->
      @brain.set 'temployments', [@temployment]
      arr = @temployments.map (temployment) -> temployment.id
      expect(arr).to.eql(['p0deje/hubot-temploy-example#4'])

  describe '#runStopScheduler()', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()
      @temployments.add(@temployment)
      @temployments.runStopScheduler()
      sinon.stub(@temployment, 'stop')

    context 'when temployment should be stopped', ->
      beforeEach ->
        sinon.stub @temployment, 'shouldBeStopped', -> true
        @clock.tick(60 * 1000)

      it 'stops temployment', ->
        expect(@temployment.stop).to.be.called

      it 'removes temployment', ->
        expect(@temployments.isEmpty()).to.eql(true)

    context 'when temployment should not be stopped', ->
      beforeEach ->
        sinon.stub @temployment, 'shouldBeStopped', -> false
        @clock.tick(60 * 1000)

      it 'does not stop temployment', ->
        expect(@temployment.stop).not.to.be.called

      it 'does not remove temployment', ->
        expect(@temployments.isEmpty()).to.eql(false)
