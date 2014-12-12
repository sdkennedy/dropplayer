AWS = require 'aws-sdk'
DOC = require 'dynamodb-doc'
Promise = require 'bluebird'
workerBuses = require './worker/buses/index'
caches = require './cache/index'

# Really just a global object for holding and configuring services

class Application
    constructor: (config, workerBus=null) ->
        @config = config
        @_workerBus = workerBus

    cache: ->
        if not @_cache?
            @_cache = caches.memory
            #Todo: add in elastic cache
        return @_cache

    db: ->
        do @initDb unless @_db?
        return @_db

    dbDoc: ->
        do @initDbDoc unless @_dbDoc?
        return @_dbDoc

    initDb: ->
        @_db = new AWS.DynamoDB( endpoint:@config.DYNAMODB_ENDPOINT, region:@config.AWS_REGION )
        Promise.promisifyAll @_db

    initDbDoc: ->
        # Using a separate AWS.DynamoDB instance because the first one has been modified with promisifyAll
        @_dbDoc = new DOC.DynamoDB( new AWS.DynamoDB( endpoint:@config.DYNAMODB_ENDPOINT, region:@config.AWS_REGION ) )
        Promise.promisifyAll @_dbDoc

    #Lazy initialization of worker bus
    workerBus: ->
        if not @_workerBus?
            @_workerBus = workerBuses[@config.WORKER_TYPE] @config
        @_workerBus

module.exports = { Application }