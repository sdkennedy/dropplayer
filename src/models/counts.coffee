_ = require 'lodash'
Promise = require 'bluebird'

countsTableProperties =
    AttributeDefinitions:[
        {
            AttributeName:"userId"
            AttributeType:"S"
        }
        {
            AttributeName:"countId"
            AttributeType:"S"
        }
    ]
    KeySchema:[
        {
            AttributeName:"userId"
            KeyType:"HASH"
        }
        {
            AttributeName:"countId"
            KeyType:"RANGE"
        }
    ]
    ProvisionedThroughput:
        ReadCapacityUnits:3
        WriteCapacityUnits:3

createTable = (app) ->
    table = _.extend TableName: app.config.DYNAMODB_TABLE_COUNTS, countsTableProperties
    app.db().createTableAsync table

deleteTable = (app) ->
    app.db().deleteTableAsync TableName: app.config.DYNAMODB_TABLE_COUNTS

incrCount = (app, userId, countId, data) -> 
    offsetCount app, userId, countId, data, 1
decrCount = (app, userId, countId, data) -> 
    offsetCount app, userId, countId, data, -1

offsetCount = (app, userId, countId, data, offset) ->
    AttributeUpdates =
        val:{ Action:"ADD", Value:offset }
    for key, val of (data ? {})
        AttributeUpdates[key] = { Action:"PUT", Value:val }

    app.dbDoc().updateItemAsync(
        TableName: app.config.DYNAMODB_TABLE_COUNTS
        Key:
            userId:userId
            countId:countId
        AttributeUpdates:AttributeUpdates
    ).catch(
        (err) ->
            newErr = new Error("Could not offsetCount(#{userId},#{countId},#{offset}): #{err.message}")
            console.log newErr.message, AttributeUpdates
            Promise.reject newErr
    )
    
queryCounts = (app, userId, prefix, query) ->
    doc = app.dbDoc()
    params = _.extend {}, (query ? {})
    params.TableName = app.config.DYNAMODB_TABLE_COUNTS
    params.KeyConditions ?= []
    params.KeyConditions = params.KeyConditions.concat [
        doc.Condition("userId", "EQ", userId)
        doc.Condition("countId", "BEGINS_WITH", prefix)
    ]
    console.log params
    doc.queryAsync( params )

getCount = (app, userId, countId) ->
    app.dbDoc().getItemAsync(
        TableName: app.config.DYNAMODB_TABLE_COUNTS
        Key:{ userId, countId }
    ).then (data) -> data.Item

module.exports = { countsTableProperties, createTable, deleteTable, incrCount, decrCount, offsetCount, queryCounts, getCount }