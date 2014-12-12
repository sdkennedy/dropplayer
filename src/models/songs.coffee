Joi = require 'joi'
Promise = require 'bluebird'
{ nullEmptyStrings, prefixTableName } = require './util'

songSchema = Joi.object().keys(

    #Primary Key
    userId:Joi.string().required()
    songId:Joi.string().required()

    #Service data
    serviceName:Joi.string().required()
    serviceSongId:Joi.string().required()
    serviceSongHash:Joi.string()

    # Metadata
    title: Joi.string()
    artist: Joi.array().includes( Joi.string() )
    album: Joi.string()
    genre: Joi.array().includes( Joi.string() )
    discNumber: Joi.number().integer()
    discNumberTotal: Joi.number().integer()
    trackNumber: Joi.number().integer()
    trackNumberTotal: Joi.number().integer()
    albumartistsort: Joi.array().includes( Joi.string() )
)

songsTableName = "songs"

createTable = (app) ->
    app.db().createTableAsync(
        TableName: app.config.DYNAMODB_TABLE_SONGS
        # Primary Key
        AttributeDefinitions:[
            {
                AttributeName:"userId"
                AttributeType:"S"
            },
            {
                AttributeName:"songId"
                AttributeType:"S"
            }
        ]
        KeySchema:[
            {
                AttributeName:"userId"
                KeyType:"HASH"
            },
            {
                AttributeName:"songId"
                KeyType:"RANGE"
            }

        ]
        ProvisionedThroughput:
            ReadCapacityUnits: 3
            WriteCapacityUnits: 3
    )

getSongId = (serviceName, serviceSongId) ->
    #encodedServiceSongId = new Buffer(serviceSongId).toString('base64')
    return "#{serviceName}.#{serviceSongId}"

putSong = (app, song) ->
    app.dbDoc().putItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SONGS
        Item:nullEmptyStrings(song)
    ).then(
        -> song
        (err) ->(
            console.log "putSong err", song, err.message
            Promise.reject( err )
        )
    )

getSong = (app, userId, songId) ->
    app.dbDoc().getItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SONGS
        Key:{ userId, songId }
    ).then (data) -> data.Item

getSongs = (app, userId) ->
    doc = app.dbDoc()
    doc.queryAsync(
        TableName: app.config.DYNAMODB_TABLE_SONGS
        KeyConditions:[ doc.Condition("userId", "EQ", userId) ]
    ).then (data) -> data.Items

module.exports = { createTable, getSongId, putSong, getSong, getSongs }