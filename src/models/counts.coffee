_ = require 'underscore'
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

incrCount = (app, userId, countId, displayName) -> 
    console.log "incrCount(#{userId},#{countId},#{displayName})"
    offsetCount app, userId, countId, displayName,  "1"
decrCount = (app, userId, countId, displayName) -> 
    offsetCount app, userId, countId, displayName, "-1"
offsetCount = (app, userId, countId, displayName, offset) ->
    console.log "offsetCount(#{userId},#{countId},#{offset})"
    app.db().updateItemAsync(
        TableName: app.config.DYNAMODB_TABLE_COUNTS
        Key:
            userId:{ S:userId }
            countId:{ S:countId }
        AttributeUpdates:
            displayName:
                Action:"PUT"
                Value:{ S:displayName }
            val:
                Action:"ADD"
                Value:{ N:offset }
    ).then(
        (res) ->
            console.log "offsetCount(#{userId},#{countId},#{displayName},#{offset}) result", res
        (err) ->
            newErr = new Error("Could not offsetCount(#{userId},#{countId},#{offset}): #{err.message}")
            console.log newErr.message
            Promise.reject newErr
    )
getCounts = (app, userId, prefix, query) ->
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

module.exports = { countsTableProperties, createTable, incrCount, decrCount, offsetCount, getCounts }