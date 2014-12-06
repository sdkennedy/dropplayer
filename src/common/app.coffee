AWS = require 'aws-sdk'
Promise = require 'bluebird'
{ initDb } = require './models/index'
workerBuses = require '../worker/buses/index'

# Really just a global object for holding and configuring services

class Application
    constructor: (config, workerBus=null) ->
        @config = config
        @_workerBus = workerBus

    #Lazy initialization of db
    db: ->
        if not @_db?
            @_db = initDb @config.DB_NAME, @config.DB_USERNAME, @config.DB_PASSWORD, @config.DB_OPTIONS
        @_db

    dbMigrator: ->
        if not @_dbMigrator
            @_dbMigrator = initDbMigrator @db()
        @_dbMigrator

    #Lazy initialization of worker bus
    workerBus: ->
        if not @_workerBus?
            @_workerBus = workerBuses[@config.WORKER_TYPE] @config
        @_workerBus

module.exports = { Application }