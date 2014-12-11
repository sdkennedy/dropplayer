Joi = require 'joi'
Promise = require 'bluebird'
_ = require 'underscore'
{ createId, prefixTableName } = require './util'
{ putUser } = require './users'

credentialsTableName = "credentials"
credentialSchema = Joi.object().keys(
    #Primary Key
    userId:Joi.string().required()
    providerId:Joi.string().required()
    service:Joi.string().required()
    displayName:Joi.string()
    email:Joi.string()
    accessToken:Joi.string()
    rootDir:Joi.string()
    cursor:Joi.string()
)
createTable = (app) ->
    app.db().createTableAsync(
        TableName:prefixTableName(app, credentialsTableName)
        # Primary Key
        AttributeDefinitions:[
            AttributeName:"providerId"
            AttributeType:"S"
        ]
        KeySchema:[
            AttributeName:"providerId"
            KeyType:"HASH"
        ]
        ProvisionedThroughput:
            ReadCapacityUnits: 3
            WriteCapacityUnits: 3
    )

credentialsToUser = (credentials) ->
    user = {
        userId:credentials.userId
        primaryEmail:credentials.email
        primaryDisplayName:credentials.displayName
        createdAt:(new Date()).toISOString()
        services:{}
    }
    user.services[ credentials.service ] = credentials.providerId
    return user

getCredentials = (app, providerId) ->
    app.dbDoc().getItemAsync(
        TableName:prefixTableName(app, credentialsTableName)
        Key:{ providerId }
        ConsistentRead:true
    ).then (data) ->
        console.log "getCredentials", data
        data.Item

putCredentials = (app, credentials) ->
    app.dbDoc().putItemAsync(
        TableName:prefixTableName(app, credentialsTableName)
        Item:credentials
    ).then -> credentials

getCredentialsOrCreate = (app, partialCredentials) ->
    getCredentials( app, partialCredentials.providerId )
        .then (credentials) ->
            if credentials?
                return credentials
            else
                credentials = _.extend {}, partialCredentials, { userId:createId() }
                # Create user and credentials
                Promise.all([
                    putUser app, credentialsToUser(credentials)
                    putCredentials app, credentials
                ]).spread (user, credentials) -> credentials


module.exports = { credentialsTableName, createTable, getCredentials, putCredentials, getCredentialsOrCreate }