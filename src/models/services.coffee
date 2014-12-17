Joi = require 'joi'
Promise = require 'bluebird'
_ = require 'underscore'
{ createId, createDate } = require './util'
{ putUser } = require './users'
errors = require '../errors'

servicesSchema = Joi.object().keys(
    #Primary Key
    userId:Joi.string().required()
    serviceId:Joi.string().required()
    serviceName:Joi.string().required()
    displayName:Joi.string()
    email:Joi.string()
    accessToken:Joi.string()
    rootDir:Joi.string()
    cursor:Joi.string()
)

servicesTableProperties =
    AttributeDefinitions:[
        {
            AttributeName:"serviceId"
            AttributeType:"S"
        }
        {
            AttributeName:"email"
            AttributeType:"S"
        }
        {
            AttributeName:"displayName"
            AttributeType:"S"
        }
    ]
    KeySchema:[
        AttributeName:"serviceId"
        KeyType:"HASH"
    ]
    GlobalSecondaryIndexes:[
        {
            IndexName: "index-email"
            KeySchema:[
                AttributeName:"email"
                KeyType:"HASH"
            ]
            Projection:
                ProjectionType: "KEYS_ONLY"
            ProvisionedThroughput:
                ReadCapacityUnits:1,
                WriteCapacityUnits:1
        }
        {
            IndexName: "index-displayName"
            KeySchema:[
                AttributeName:"displayName"
                KeyType:"HASH"
            ]
            Projection:
                ProjectionType: "KEYS_ONLY"
            ProvisionedThroughput:
                ReadCapacityUnits:1,
                WriteCapacityUnits:1
        }
    ]
    ProvisionedThroughput:
        ReadCapacityUnits:1,
        WriteCapacityUnits:1

createTable = (app) ->
    table = _.extend TableName: app.config.DYNAMODB_TABLE_SONGS, servicesTableProperties
    app.db().createTableAsync table

serviceToUser = (service) ->
    user = {
        userId:service.userId
        primaryEmail:service.email
        primaryDisplayName:service.displayName
        createdAt:createDate()
        services:{}
    }
    user.services[ service.serviceName ] = service.serviceId
    return user

getService = (app, serviceId) ->
    app.dbDoc().getItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SERVICES
        Key:{ serviceId }
        ConsistentRead:true
    ).then(
        (data) -> data.Item
        (err) -> Promise.reject( new Error("Could not getService #{ JSON.stringify(serviceId) }: #{err.message}") )
    )

putService = (app, service) ->
    app.dbDoc().putItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SERVICES
        Item:service
    ).then(
        -> service
        -> Promise.reject( new Error("Could not putService #{service?.serviceId}") )
    )

getServiceOrCreate = (app, partialService) ->
    getService( app, partialService.serviceId )
        .then (service) ->
            if service?
                return service
            else
                service = _.extend {}, partialService, { userId:createId() }
                # Create user and service
                Promise.all([
                    putUser app, serviceToUser(service)
                    putService app, service
                ])

createIndex = (app, service) ->
    if not service?.index?.endAt?
        delete service.index if service.index?
        service.serviceIndex = {
            startAt:createDate()
            endAt:null
            finishedSearch:false
            finishedIndexing:false
            numFound:0
            numIndexed:0
            numRemoved:0
            numErrors:0
        }

        putService app, service
            .then(
                -> service
                (err) -> Promise.reject( new Error("Could not create index: #{err.message}") )
            )
    else
        Promise.reject new IndexRunningError(service.serviceName)

incrIndexCount = (app, serviceId, key, amount=1) ->
    app.dbDoc().updateItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SERVICES
        Key:{ serviceId },
        UpdateExpression:"SET serviceIndex.#{key} = serviceIndex.#{key} + :x"
        ExpressionAttributeValues: ":x" : amount
    ).then(
        ->
        (err) -> Promise.reject( new Error("Could not incrIndexCount(#{serviceId},#{key}): #{err.message}") )
    )

setIndexCount = (app, serviceId, key, count) ->
    app.dbDoc().updateItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SERVICES
        Key:{ serviceId },
        UpdateExpression:"SET serviceIndex.#{key} = :x"
        ExpressionAttributeValues: ":x" : count
    ).then(
        -> #console.log "incrIndexCount(#{serviceId}, #{key}, #{amount}): success"
        (err) ->
            #console.log "incrIndexCount(#{serviceId}, #{key}, #{amount}): error"
            Promise.reject( new Error("Could not incrIndexCount(#{serviceId},#{key}): #{err.message}") )
    )

module.exports = { createTable, servicesTableProperties, getService, putService, getServiceOrCreate, createIndex, incrIndexCount, setIndexCount }