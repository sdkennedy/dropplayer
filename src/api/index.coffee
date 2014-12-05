express = require 'express'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
cookieSession = require 'cookie-session'
initErrors = require './routes/errors'
initAuth = require './routes/auth'
initUsers = require './routes/users'
{ Application } = require '../common/app'
EagerWorker = require '../worker/workers/eager'
{ workerTypes } = require '../worker/constants'

class Api extends Application
    constructor: (config, workerBus=null) ->
        super config, workerBus

        #Setup express
        @express = @initExpress @config
        do @initRoutes

        #Setup eager worker if necessary
        @initEagerWorker(@config) if @config.WORKER_TYPE is workerTypes.eager

    initExpress: (config) ->
        app = express()

        app.use cookieParser()
        app.use bodyParser.json()
        app.use cookieSession({
            name:"session"
            secret:"S3AD0CeRO3C"
            keys: ['PP8lD9a099R1' , 'L20F0B008D9PR']
            signed: true
            cookie:
                maxAge: 43200000 # 0.5 day
        })

        return app

    initRoutes: ->
        initAuth @
        initUsers @
        initErrors @

    initEagerWorker: (config) ->
        @eagerWorker = new EagerWorker config, @workerBus()

    listen: ->
        @express.listen @config.API_HOST.port
        @eagerWorker?.listen()
        #console.log app._router.stack
        console.log "Listening on port #{ @config.API_HOST.port }"


module.exports = { Api }