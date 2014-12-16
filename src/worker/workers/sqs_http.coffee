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
                stream.onEnd -> res.status(200)
                stream.onError (err) -> res.status(500).json(err)
        )

    listen: ->
        @express.listen @config.PORT
        console.log @express._router.stack.map (route) -> [ route.name, route.regexp ]
        console.log "Listening on port #{ @config.PORT }"

module.exports = HttpSQSWorker