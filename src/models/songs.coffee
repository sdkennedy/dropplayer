Joi = require 'joi'
Promise = require 'bluebird'
_ = require 'lodash'
{ nullEmptyStrings, prefixTableName, createQueryParams } = require './util'
{ putAlbumBySong } = require './song_albums'
{ putPrimaryArtistBySong } = require './song_artists'
{ putPrimaryGenreBySong } = require './song_genres'

songSchema = Joi.object().keys(

    #Primary Key
    userId:Joi.string().required()
    songId:Joi.string().required()

    #Service data
    serviceId:Joi.string().required()
    serviceSongId:Joi.string().required()
    serviceSongHash:Joi.string()

    # Metadata
    title: Joi.string()
    artist: Joi.array().includes( Joi.string() )
    album: Joi.string()
    primaryGenre: Joi.string()
    genre: Joi.array().includes( Joi.string() )
    discNumber: Joi.number().integer()
    discNumberTotal: Joi.number().integer()
    trackNumber: Joi.number().integer()
    trackNumberTotal: Joi.number().integer()
    primaryAlbumArtistSort: Joi.array().includes( Joi.string() )
    albumArtistSort: Joi.array().includes( Joi.string() )
)

songsTableName = "songs"

songTableProperties =
    AttributeDefinitions:[
        {
            AttributeName:"userId"
            AttributeType:"S"
        }
        {
            AttributeName:"songId"
            AttributeType:"S"
        }
        {
            AttributeName:"title"
            AttributeType:"S"
        }
        {
            AttributeName:"primaryArtist"
            AttributeType:"S"
        }
        {
            AttributeName:"album"
            AttributeType:"S"
        }
        {
            AttributeName:"primaryGenre"
            AttributeType:"S"
        }
        {
            AttributeName:"primaryAlbumArtistSort"
            AttributeType:"S"
        }
    ]
    KeySchema:[
        {
            AttributeName:"userId"
            KeyType:"HASH"
        }
        {
            AttributeName:"songId"
            KeyType:"RANGE"
        }
    ]
    LocalSecondaryIndexes:[
        {
            IndexName:"index-title"
            KeySchema:[
                {
                  AttributeName: "userId"
                  KeyType: "HASH"
                }
                {
                  AttributeName: "title"
                  KeyType: "RANGE"
                }
            ]
            Projection:
                ProjectionType: "ALL"
        }
        {
            IndexName:"index-primaryArtist"
            KeySchema:[
                {
                  AttributeName: "userId"
                  KeyType: "HASH"
                }
                {
                  AttributeName: "primaryArtist"
                  KeyType: "RANGE"
                }
            ]
            Projection:
                ProjectionType: "ALL"
        }
        {
            IndexName:"index-album"
            KeySchema:[
                {
                  AttributeName: "userId"
                  KeyType: "HASH"
                }
                {
                  AttributeName: "album"
                  KeyType: "RANGE"
                }
            ]
            Projection:
                ProjectionType: "ALL"
        }
        {
            IndexName:"index-primaryGenre"
            KeySchema:[
                {
                  AttributeName: "userId"
                  KeyType: "HASH"
                }
                {
                  AttributeName: "primaryGenre"
                  KeyType: "RANGE"
                }
            ]
            Projection:
                ProjectionType: "ALL"
        }
        {
            IndexName:"index-primaryAlbumArtistSort"
            KeySchema:[
                {
                  AttributeName: "userId"
                  KeyType: "HASH"
                }
                {
                  AttributeName: "primaryAlbumArtistSort"
                  KeyType: "RANGE"
                }
            ]
            Projection:
                ProjectionType: "ALL"
        }
    ]
    ProvisionedThroughput:
        ReadCapacityUnits:3
        WriteCapacityUnits:3

createTable = (app) ->
    table = _.extend TableName: app.config.DYNAMODB_TABLE_SONGS, songTableProperties
    app.db().createTableAsync table

getSongId = (serviceId, serviceSongId) ->
    encodedSericeSongId = new Buffer(serviceSongId).toString('base64')
    "#{serviceId}.#{encodedSericeSongId}"

putSong = (app, song) ->
    Promise.resolve song
        # Sanitize Song
        .then nullEmptyStrings
        # Save song to database
        .then (song) ->
            newSong = _.extend {}, song
            delete newSong.pictures
            app.dbDoc().putItemAsync
                TableName: app.config.DYNAMODB_TABLE_SONGS
                Item:newSong
            .then(
                -> song
                (err) ->(
                    console.log "putSong err", err.message, err.stack, song
                    Promise.reject( err )
                )
            )

removeSong = (app, userId, songId) ->
    app.dbDoc().deleteItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SONGS
        Key:{ userId, songId }
    ).then (data) -> data.Item

getSong = (app, userId, songId) ->
    app.dbDoc().getItemAsync(
        TableName: app.config.DYNAMODB_TABLE_SONGS
        Key:{ userId, songId }
    ).then (data) -> data.Item

querySongs = (app, userId, params) ->
    doc = app.dbDoc()
    params = createQueryParams(
        app.config.DYNAMODB_TABLE_SONGS
        doc.Condition("userId", "EQ", userId)
        params
    )
    console.log params
    doc.queryAsync( params )

module.exports = {
    createTable
    songTableProperties
    getSongId
    putSong
    getSong
    querySongs
}