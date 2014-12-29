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
        console.log "processAction", typeof action, action.type, handler
        if handler?
            # Allow stream to be retried up to 3 times
            return Bacon.retry(
                source: -> handler(action)
                retries: 3
                delay: -> 100
            )
        else
            return Bacon.once new Bacon.Error( new errors.NotFound("Worker handler for #{ action.type }") )

    registerHandlers: ->
        initIndexers(@)

    registerHandler: (type, handler) -> @handlers[type] = handler

module.exports = Worker