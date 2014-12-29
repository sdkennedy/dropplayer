Bacon = require 'baconjs'
# Express libraries
express = require 'express'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
cookieSession = require 'cookie-session'
passport = require 'passport'
# Application
{ Application } = require '../util/app'
EagerWorker = require '../worker/workers/eager'
Worker = require '../worker/workers/worker'
{ workerTypes } = require '../worker/constants'
#Routing Related
services = require '../services/index'
initRoutes = require './routes'

class Api extends Application
    constructor: (config, workerBus=null) ->
        super config, workerBus

        #Setup express
        @express = @initExpress @config
        do @initPassport
        do @initRoutes

        #Setup eager worker if necessary
        @initEagerWorker(@config) if @config.WORKER_TYPE is workerTypes.eager

    initExpress: (config) ->
        app = express()
        app.enable 'trust proxy'
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

    worker: ->
        if not @_worker?
            @_worker = new Worker @config
        return @_worker

    initPassport: ->
        # Initialize Passport
        @express.use passport.initialize()
        @express.use passport.session()
        # Session is stored in signed cookie so only store the user.id
        passport.serializeUser (id, done) ->  done(null, id)
        passport.deserializeUser (id, done) -> done(null, id)


    initRoutes: ->
        initRoutes @
        for serviceName, service of services
            console.log("initializing routing for", serviceName) if @config.DEBUG
            service.initRoutes @


    initEagerWorker: (config) ->
        @eagerWorker = new EagerWorker config, @workerBus()

    listen: ->
        @express.listen @config.PORT
        @eagerWorker?.listen()

        #console.log @express._router.stack
        #console.log @express._router.stack.map (route) -> [ route.name, route.regexp ]
        console.log "Listening on port #{ @config.PORT }"


module.exports = { Api }