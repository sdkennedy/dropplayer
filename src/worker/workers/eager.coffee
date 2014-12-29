Worker = require './worker'
{ Bacon } = require 'baconjs'

class EagerWorker extends Worker
    constructor: (config, workerBus) ->
        super config, workerBus

    listen: ->
        stream = @workerBus()
            .flatMapWithConcurrencyLimit 20, (action) =>
                Bacon.fromPromise @processAction(action)
        stream.onValue -> #Discard result
        stream.onError (err) -> console.log "stream error"

module.exports = EagerWorker