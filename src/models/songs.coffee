Joi = require 'joi'
Promise = require 'bluebird'
_ = require 'underscore'
mime = require 'mime'
sizeOf = require 'image-size'
crypto = require 'crypto'
{ nullEmptyStrings, prefixTableName, createQueryParams } = require './util'
{ incrCount, getCounts } = require './counts'

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

getS3Url = (region, bucket, key) -> "https://s3-#{region}.amazonaws.com/#{bucket}/#{key}"
getS3Bucket = -> "dropplayer-songs"
getS3Key = (picture) -> 
    hash = crypto.createHash('sha256').update( picture.data ).digest('hex')
    "#{ hash }.#{picture.format}"

createSongBucket = (app, userId) ->
    bucketName = getS3Bucket()
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
        song.pictures = Promise.all song.pictures.map (picture) -> savePicture app, song, picture
    return Promise.props song

savePicture = (app, song, picture) ->
    dimensions = sizeOf picture.data
    Promise.props(
        url: savePictureToS3 app, song, picture
        width: dimensions.width
        height: dimensions.height
        type: picture.format
    )

pictureExists = (app, song, picture) ->
    app.aws('S3').headObjectAsync(
        Bucket: getS3Bucket()
        Key: getS3Key picture
    ).then(
        (result) -> true
        (err) ->
            if err?.cause?.code is "NotFound"
                return false
            else
                Promise.reject err
    )

savePictureToS3 = (app, song, picture) ->
    bucketName = getS3Bucket()
    key = getS3Key picture

    console.log "Creating picture bucket:#{bucketName} key:#{key}"

    pictureExists app, song, picture
        .then (exists) ->
            if not exists
                app.aws('S3').putObjectAsync(
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
                            .then -> savePicture app, song, picture
                    else
                        Promise.reject err
            else
                return Promise.resolve()
        .then -> getS3Url app.config.AWS_REGION, bucketName, key

incrSongAttrCount = (app, song, key) ->
    if song[ key ]?
        countKey = "songs.#{key}.#{song[key]}"
        incrCount app, song.userId, countKey, song[key]
    else
        Promise.resolve()

incrSongCounts = (app, song) ->
    Promise.all(
        incrSongAttrCount app, song, 'album'
        incrSongAttrCount app, song, 'primaryArtist'
        incrSongAttrCount app, song, 'primaryGenre'
    )

putSong = (app, song) ->
    Promise.resolve(song)
        # Sanitize Song
        .then nullEmptyStrings
        # Save pictures to S3
        .then (song) -> savePictures app, song
        # Save song to database
        .then (song) ->
            app.dbDoc().putItemAsync
                TableName: app.config.DYNAMODB_TABLE_SONGS
                Item:song
            .then(
                -> song
                (err) ->(
                    console.log "putSong err", err.message, err.stack, song
                    Promise.reject( err )
                )
            )
        .tap (song) -> incrSongCounts app, song

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

getAlbums = (app, userId, query) ->
    console.log "getAlbums"
    getCounts app, userId, "songs.album", query
getArtists = (app, userId, query) ->
    console.log "getArtist"
    getCounts app, userId, "songs.primaryArtist", query
getGenres = (app, userId, query) -> 
    getCounts app, userId, "songs.primaryGenre", query

module.exports = {
    createTable
    songTableProperties
    getSongId
    putSong
    getSong
    getSongs
    getAlbums
    getArtists
    getGenres
}