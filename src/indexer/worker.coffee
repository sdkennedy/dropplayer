{ getUser } = require '../models/users'
songs = require '../models/songs'
{ getSongId, putSong, getSong } = songs
removeSongEntity = songs.removeSong
{ getService, incrIndexCount, setIndexCount } = require '../models/services'
services = require '../services/index'
# Indexer Libraries
actions = require './actions'
{ actionKeys } = require './constants'
# Third Part Libraries
{ Bacon } = require 'baconjs'
Promise = require 'bluebird'
request = require 'request'
musicMetadata = require 'musicmetadata'
_ = require 'underscore'

indexService = do (->
    callChangeAction = (app, serviceId, userId, change) ->
        try
            if actions[change.action]?
                action = actions[change.action]
                Bacon.fromPromise action(
                    app,
                    userId,
                    serviceId,
                    change.serviceSongId,
                    change.serviceSongHash,
                    change.request,
                    change.fileSize
                )
            else
                new Bacon.Error("Could no find indexer action for #{change.action}")
        catch err
            new Bacon.Error(err)

    return (app, serviceId, full) ->
        try
            console.log "indexService(#{serviceId}, #{full})"
            Bacon
                # Get service from database
                .fromPromise getService( app, serviceId )
                .flatMap (service) ->
                    # Get changes from service
                    changesStream = services[ service.serviceName ].getChanges app, service, full

                    #Increment count at most once every 250ms
                    changesStream
                        .scan 0, (acc, val) -> acc + 1
                        .throttle 250
                        .onValue (value) ->
                            if value > 0
                                console.log "setting numFound #{value}"
                                setIndexCount app, serviceId, "numFound", value

                    # Create subsequent index / delete action
                    return changesStream.flatMap (change) ->
                        callChangeAction app, serviceId, service.userId, change
                #Bring all changes back together into a single event when complete
                .fold(null, ->)
                .toEventStream()
        catch err
            return Bacon.Error err
)

indexSong = do (->
    sanitizeMetadata = (metadata) ->
        _.reduce(
            metadata,
            (newMetadata, val, key) ->
                if val is ""
                    newVal = null
                else if _.isArray(val)
                    newVal = val.map (subVal) -> if subVal is "" then null else subVal
                else
                    newVal = val
                newMetadata[key] = newVal
                return newMetadata
            {}
        )

    getMetadata = (req, fileSize) ->
        return new Bacon.fromBinder((sink)->
            try
                parser = musicMetadata(
                    #Request can't be created outside of musicMetadata because stream will start sending data immediately
                    reqStream = request(req)
                    fileSize:fileSize
                )
                reqStream.on 'error', (err) ->
                    console.log 'reqest error', err
                    sink new Bacon.Error( err )
                parser.on 'metadata', (result) -> sink new Bacon.Next( sanitizeMetadata(result) )
                parser.on 'done', (err) ->
                    reqStream.destroy()
                    if err?
                        console.error err
                        sink new Bacon.Error(err)
                    sink new Bacon.End()
            catch err
                # Catch any uncaught errors
                sink new Bacon.Error(err)
                sink new Bacon.End()
            finally
                return -> reqStream.destroy()
        )

    createSong = (app, userId, serviceId, serviceSongId, serviceSongHash, metadata) ->
        try
            data =
                # Who owns it
                userId: userId
                songId: getSongId serviceId, serviceSongId
                # Where is came from
                serviceId:serviceId
                serviceSongId:serviceSongId
                serviceSongHash:serviceSongHash

                # Metadata columns
                title: metadata.title
                artist: metadata.artist
                album: metadata.album
                genre: metadata.genre
                discNumber: metadata.disk?.no
                discNumberTotal: metadata.disk?.of
                trackNumber: metadata.track?.no
                trackNumberTotal: metadata.track?.of
                albumArtistSort: metadata.albumartist

            return Bacon.fromPromise putSong( app, data)
        catch err
            return new Bacon.Error err

    return (app, userId, serviceId, serviceSongId, serviceSongHash, req, fileSize) ->
        console.log "indexSong(#{userId}, #{serviceId}, #{serviceSongId})"
        try
            songId = getSongId serviceId, serviceSongId
            stream = Bacon.fromPromise getSong(app, userId, songId)
                #Only continue if song is nonexistant or hash different
                .flatMap (existingSong) -> if existingSong? then Bacon.never() else Bacon.once()
                # Get song metadata
                .flatMap ->
                    Bacon.retry(
                        source: -> getMetadata(req, fileSize)
                        retries: 3
                        delay: 100
                    )
                # Create song in database
                .flatMap (metadata) -> createSong app, userId, serviceId, serviceSongId, serviceSongHash, metadata
                # Log how many songs have errors
                .mapError (err) ->
                    incrIndexCount app, serviceId, "numErrors"
                    new Bacon.Error(err)
                # Log how many songs were indexed correctly
                .doAction -> incrIndexCount app, serviceId, "numIndexed"

            return stream
        catch err
            # Catch any uncaught errors
            return new Bacon.Error(err)
)

removeSong = (app, userId, serviceId, serviceSongId, serviceSongHash, req) ->
    console.log "removeSong(#{userId}, #{serviceId}, #{serviceSongId})"
    songId = getSongId serviceId, serviceSongId
    removeSongEntity app, userId, songId

#Associate an action key with a function to handle the request
module.exports = (worker) ->
    worker.registerHandler(
        actionKeys.indexService,
        (action) ->
            indexService(
                worker,
                action.serviceId
                action.full
            )
    )
    worker.registerHandler(
        actionKeys.indexSong,
        (action) ->
            indexSong(
                worker,
                action.userId,
                action.serviceId,
                action.serviceSongId,
                action.serviceSongHash,
                action.request,
                action.fileSize
            )
    )
    worker.registerHandler(
        actionKeys.removeSong,
        (action) ->
            removeSong(
                worker,
                action.userId,
                action.serviceId,
                action.serviceSongId,
                change.serviceSongHash,
                action.request
            )
    )