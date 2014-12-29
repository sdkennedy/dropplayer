Worker = require './worker'
# Express libraries
express = require 'express'
bodyParser = require 'body-parser'

class HttpSQSWorker extends Worker
    constructor: (config, workerBus) ->
        super config, workerBus
        @express = @initExpress @config
        do @initRoutes

    initExpress: (config) ->
        app = express()
        app.enable 'trust proxy'
        app.use bodyParser.json()
        return app

    initRoutes: ->
        @express.post(
            "/",
            (req, res) =>
                console.log "Worker request", req.body
                stream = @processAction req.body
                    .endOnError()
                stream.onValue (result) ->
                    console.log "Worker result", result
                    res.status(200).json result
                stream.onError (err) ->
                    console.log "Worker error", err
                    console.log("Worker error stack", err.stack) if err?.stack?
                    res.status(500).json err
        )

    listen: ->
        @express.listen @config.PORT
        console.log @express._router.stack.map (route) -> [ route.name, route.regexp ]
        console.log "Listening on port #{ @config.PORT }"

module.exports = HttpSQSWorker