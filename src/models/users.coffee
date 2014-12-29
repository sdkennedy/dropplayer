Joi = require 'joi'
_ = require 'lodash'
{ asyncValidate } = require '../util/joi'
{ createId, prefixTableName } = require './util'

usersTableProperties =
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

createTable = (app) ->
    table = _.extend TableName: app.config.DYNAMODB_TABLE_USERS, usersTableProperties
    app.db().createTableAsync table

deleteTable = (app) ->
    app.db().deleteTableAsync TableName: app.config.DYNAMODB_TABLE_USERS

userSchema = Joi.object().keys(
    userId: Joi.string().required()
    primaryEmail: Joi.string().required()
    primaryDisplayName: Joi.string().required()
    dropbox: Joi.object()
)

scanUsers = (app) ->
    app.dbDoc().scanAsync TableName: app.config.DYNAMODB_TABLE_USERS

getUser = (app, userId) ->
    app.dbDoc().getItemAsync(
        TableName: app.config.DYNAMODB_TABLE_USERS
        Key:{ userId }
        ConsistentRead:true
    ).then (data) ->
        console.log "getUser", data
        data.Item

putUser = (app, user) ->
    app.dbDoc().putItemAsync(
        TableName: app.config.DYNAMODB_TABLE_USERS
        Item:user
    ).then -> user

module.exports = { usersTableProperties, createTable, deleteTable, scanUsers, getUser, putUser }