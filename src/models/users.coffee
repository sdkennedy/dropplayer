Joi = require 'joi'
_ = require 'underscore'
{ asyncValidate } = require '../util/joi'
{ createId, prefixTableName } = require './util'

usersTableName = "users"

createTable = (app) ->
    app.db().createTableAsync(
        TableName:prefixTableName(app, usersTableName)
        # Primary Key
        AttributeDefinitions:[
            AttributeName:"userId"
            AttributeType:"S"
        ]
        KeySchema:[
            AttributeName:"userId"
            KeyType:"HASH"
        ]
        ProvisionedThroughput:
            ReadCapacityUnits: 3
            WriteCapacityUnits: 3
    )

userSchema = Joi.object().keys(
    userId: Joi.string().required()
    primaryEmail: Joi.string().required()
    primaryDisplayName: Joi.string().required()
    dropbox: Joi.object()
)

getUser = (app, userId) ->
    app.dbDoc().getItemAsync(
        TableName:prefixTableName(app, usersTableName)
        Key:{ userId }
        ConsistentRead:true
    ).then (data) ->
        console.log "getUser", data
        data.Item

putUser = (app, user) ->
    app.dbDoc().putItemAsync(
        TableName:prefixTableName(app, usersTableName),
        Item:user
    ).then -> user

module.exports = { createTable, createTable, getUser, putUser }