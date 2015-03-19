class TemploymentCollection

  constructor: (brain) ->
    @brain = brain

  isEmpty: ->
    @_getTemployments().length == 0

  get: (id) ->
    @_getTemployments().filter((x) -> x.id == id)[0]

  add: (temployment) ->
    temployments = @_getTemployments()
    temployments.push(temployment)
    @_setTemployments(temployments)

  remove: (id) ->
    temployments = @_getTemployments().filter((x) -> x.id != id)
    @_setTemployments(temployments)

  map: (fn) ->
    @_getTemployments().map(fn)

  runStopScheduler: ->
    setInterval =>
      @map (temployment) =>
        if temployment.shouldBeStopped()
          temployment.stop()
          @remove(temployment.id)
    , 60 * 1000

  # private

  _getTemployments: ->
    @_setTemployments([]) unless @brain.get('temployments')
    @brain.get('temployments')

  _setTemployments: (temployments) ->
    @brain.set('temployments', temployments)


module.exports = TemploymentCollection
