Promise = require 'bluebird'
mime = require 'mime'
sizeOf = require 'image-size'
crypto = require 'crypto'

getS3Url = (region, bucket, key) -> "https://s3-#{region}.amazonaws.com/#{bucket}/#{key}"
getS3Bucket = -> "dropplayer-cover-art"
getS3Key = (picture) -> 
    hash = crypto.createHash('sha256').update( picture.data ).digest('hex')
    "#{ hash }.#{picture.format}"

createCoverArtBucket = (app, userId) ->
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

saveMetadataPictures = (app, song, pictures) ->
    if pictures? and pictures.length > 0
        console.log "Saving pictures", pictures
        return Promise.all pictures.map (picture) -> savePicture app, song, picture
    else
        return Promise.resolve([])

savePicture = (app, song, picture) ->
    dimensions = sizeOf picture.data
    Promise.props(
        url: saveToS3 app, song, picture
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

saveToS3 = (app, song, picture) ->
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
                        createCoverArtBucket app, song.userId
                            .then -> savePicture app, song, picture
                    else
                        Promise.reject err
            else
                return Promise.resolve()
        .then -> getS3Url app.config.AWS_REGION, bucketName, key

module.exports = { saveMetadataPictures }