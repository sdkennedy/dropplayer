Worker = require './worker'
{ Bacon } = require 'baconjs'

class EagerWorker extends Worker
    constructor: (config, workerBus) ->
        super config, workerBus

    listen: ->
        stream = @workerBus()
            .flatMapWithConcurrencyLimit(
                20,
                (action) =>
                    Bacon.retry(
                        source: => @processAction(action)
                        retries: 5
                        delay: 100
                    )
            )
        stream.onValue -> #Discard result
        stream.onError (err) -> console.log err


module.exports = EagerWorker