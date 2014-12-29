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
            return handler action
        else
            Promise.reject new errors.NotFound("Worker handler for #{ action.type }")

    registerHandlers: ->
        initIndexers(@)

    registerHandler: (type, handler) -> @handlers[type] = handler

module.exports = Worker