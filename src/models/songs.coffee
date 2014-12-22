Joi = require 'joi'
Promise = require 'bluebird'
_ = require 'underscore'
mime = require 'mime'
{ nullEmptyStrings, prefixTableName, createQueryParams } = require './util'

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


getSongBucketName = (userId) -> "dropplayer-songs-#{ userId }"

createSongBucket = (app, userId) ->
    bucketName = getSongBucketName userId
    console.log "Creating bucket", bucketName
    app.aws('S3').createBucketAsync(
        ACL:"public-read"
        Bucket: bucketName
        CreateBucketConfiguration:
            LocationConstraint: app.config.AWS_REGION
    ).then(
        (result) ->
            console.log "Successfully saved bucket", result
            return result
        (err) ->
            console.log "Could not create bucket:", err
            Promise.reject err
    )

hasPictures = (song) -> song?.pictures? and song.pictures.length > 0

savePictures = (app, song) ->
    if hasPictures(song)
        console.log "Saving pictures", song.pictures
        song.pictures = Promise.all song.pictures.map (picture, i) -> savePicture app, i, song, picture
    return Promise.props(song).then (song) ->
        console.log( "savePictures result", song ) if hasPictures( song )
        return song

savePicture = (app, i, song, picture) ->
    bucketName = getSongBucketName song.userId
    key = "#{song.songId}-#{i}.#{picture.format}"

    console.log "Creating picture bucket:#{bucketName} key:#{key}"

    s3 = app.aws('S3')
    s3.putObjectAsync(
        ACL: "public-read"
        Bucket: bucketName
        ContentType: mime.lookup picture.format
        Key: key
        Body: picture.data
    ).catch (err) ->
        console.log "Error saving picture to S3", err
        if err?.cause?.code is "NoSuchBucket"
            # Create the bucket then try again
            createSongBucket app, song.userId
                .then -> savePicture app, i, song, picture
        else
            Promise.reject err
    .then -> 
        console.log "Saved picture"
        s3.getSignedUrlAsync 'getObject', Bucket: bucketName, Key: key
        
        

putSong = (app, song) ->
    sanitizedSong = nullEmptyStrings(song)

    Promise.resolve(song)
        .then (song) -> savePictures app, sanitizedSong
        .then (song) ->
            if hasPictures(song)
                debugger
                app.dbDoc().putItemAsync TableName: app.config.DYNAMODB_TABLE_SONGS, Item:sanitizedSong
                    .catch (err) ->(
                        console.log "putSong err", err.message, err.stack, song
                        Promise.reject( err )
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

getSongs = (app, userId, queryParams) ->
    doc = app.dbDoc()
    params = createQueryParams(
        app.config.DYNAMODB_TABLE_SONGS
        doc.Condition("userId", "EQ", userId)
        queryParams
    )
    console.log params
    doc.queryAsync( params )

module.exports = { createTable, songTableProperties, getSongId, putSong, getSong, getSongs }