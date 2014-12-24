{ Application } = require '../../util/app'
initIndexers = require '../../indexer/worker'
Promise = require 'bluebird'
{ Bacon } = require 'baconjs'
errors = require '../../errors'

class Worker extends Application
    constructor: (config, workerBus=null) ->
        super config, workerBus
        @handlers = {}
        do @registerHandlers

    # returns: bacon stream
    processAction: (action) ->
        handler = @handlers[action.type]
        if handler?
            stream = handler(action)
            stream.onError (err) ->
                    console.log "Worker handler error", err
                    console.log("Worker handler error stack", err.stack) if err?.stack?
            stream.onValue -> # Do nothing, but make sure stream starts running
            return stream
        else
            Bacon.once new Bacon.Error( new errors.NotFound("Worker handler") )

    registerHandlers: ->
        initIndexers(@)

    registerHandler: (type, handler) -> @handlers[type] = handler

module.exports = Worker