AWS = require 'aws-sdk'
DOC = require 'dynamodb-doc'
Promise = require 'bluebird'
workerBuses = require '../worker/buses/index'
caches = require '../cache/index'

# Really just a global object for holding and configuring services

class Application
    constructor: (config, workerBus=null) ->
        @config = config
        @_workerBus = workerBus
        @_awsServices = {}

    cache: ->
        if not @_cache?
            @_cache = caches.memory
            #Todo: add in elastic cache
        return @_cache

    db: ->
        unless @_db?
            console.log "Initializing DynamoDb"
            @_db = new AWS.DynamoDB(
                credentials:@awsCredentials()
                endpoint:@config.DYNAMODB_ENDPOINT
                region:@config.AWS_REGION
            )
            Promise.promisifyAll @_db
            @listTables @_db
        return @_db

    dbDoc: ->
        unless @_dbDoc?
            db = new AWS.DynamoDB(
                credentials:@awsCredentials()
                endpoint:@config.DYNAMODB_ENDPOINT
                region:@config.AWS_REGION
            )
            @listTables db
            @_dbDoc = new DOC.DynamoDB db
            Promise.promisifyAll @_dbDoc
        return @_dbDoc

    listTables: (db) ->
        db.listTables (err, data) ->
            console.log("Existing tables", data.TableNames) if not err?
            console.log("Error getting existing tables", err) if err?

    # Allows reuse of aws services
    aws: (className, props) ->
        unless @_awsServices[className]?
            props ?= {}
            props.credentials = @awsCredentials()
            @_awsServices[className] = new AWS[className](props)
            Promise.promisifyAll @_awsServices[className]
        return @_awsServices[className]

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