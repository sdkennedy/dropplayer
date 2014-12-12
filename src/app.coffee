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
        unless @_db?
            @_db = new AWS.DynamoDB(
                credentials:@awsCredentials()
                endpoint:@config.DYNAMODB_ENDPOINT
                region:@config.AWS_REGION
            )
            Promise.promisifyAll @_db
        return @_db

    dbDoc: ->
        unless @_dbDoc?
            @_dbDoc = new DOC.DynamoDB(
                new AWS.DynamoDB(
                    credentials:@awsCredentials()
                    endpoint:@config.DYNAMODB_ENDPOINT
                    region:@config.AWS_REGION
                )
            )
            Promise.promisifyAll @_dbDoc
        return @_dbDoc

    awsCredentials: ->
        unless @_awsCredentials?
            @_awsCredentials = switch @config.AWS_CREDENTIALS_TYPE
                when "iam" then new AWS.EC2MetadataCredentials()
                when "shared" then new AWS.SharedIniFileCredentials()
        return @_awsCredentials

    #Lazy initialization of worker bus
    workerBus: ->
        if not @_workerBus?
            @_workerBus = workerBuses[@config.WORKER_TYPE] @
        @_workerBus

module.exports = { Application }