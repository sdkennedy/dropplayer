{ getUser } = require '../models/users'
{ getCredentials } = require '../models/credentials'
{ getSongId, putSong, getSong } = require '../models/songs'
{ incrIndexCount } = require '../models/indexes'
services = require '../services/index'
# Indexer Libraries
actions = require './actions'
{ actionKeys } = require './constants'
# Third Part Libraries
{ Bacon } = require 'baconjs'
Promise = require 'bluebird'
request = require 'request'
musicMetadata = require 'musicmetadata'

indexService = do (->
    callChangeAction = (app, userId, serviceName, change) ->
        try
            if actions[change.action]?
                action = actions[change.action]

                Bacon.fromPromise action(
                    app,
                    userId,
                    serviceName,
                    change.serviceSongId,
                    change.serviceSongHash,
                    change.request,
                    change.fileSize
                )
            else
                new Bacon.Error("Could no find indexer action for #{change.action}")
        catch err
            new Bacon.Error(err)

    return (app, userId, serviceName) ->
        try
            if not services[ serviceName ]?
                return new Bacon.Error("No indexer for service #{serviceName}")

            console.log "indexService", userId, serviceName

            Bacon
                .fromPromise getUser( app, userId )
                .flatMap (user) ->
                    if user?
                        Bacon.fromPromise getCredentials( app, user.services[serviceName] )
                    else
                        new Bacon.Error("")
                .flatMap (credentials) -> services[serviceName].getChanges(credentials)
                .doAction -> incrIndexCount( app, userId, serviceName, "numFound" )
                .flatMap (change) -> callChangeAction(app, userId, serviceName, change)
                #Bring all changes back together into a single event when complete
                .fold(null, ->)
                .toEventStream()
        catch err
            return Bacon.Error(err)
)

indexSong = do (->
    getMetadata = (req, fileSize) ->
        return new Bacon.fromBinder((sink)->
            try
                parser = musicMetadata(
                    #Request can't be created outside of musicMetadata because stream will start sending data immediately
                    reqStream = request(req)
                    fileSize:fileSize
                )
                reqStream.on 'error', (err) -> console.log 'reqest error', err
                parser.on 'metadata', (result) -> sink new Bacon.Next(result)
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

    createSong = (app, userId, songId, serviceName, serviceSongId, serviceSongHash, metadata) ->
        try
            data =
                # Who owns it
                userId: userId
                songId: songId
                # Where is came from
                serviceName:serviceName
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

    return (app, userId, serviceName, serviceSongId, serviceSongHash, req, fileSize) ->
        try
            songId = getSongId(serviceName, serviceSongId)
            stream = Bacon.fromPromise getSong(app, userId, songId)
                .flatMap (existingSong) -> (
                    #Only continue if song is nonexistant or hash different
                    if existingSong? then Bacon.never() else Bacon.once()
                )
                .flatMap -> getMetadata(req, fileSize)
                .flatMap (metadata) -> createSong(app, userId, songId, serviceName, serviceSongId, serviceSongHash, metadata)
                .mapError (err) ->
                    incrIndexCount app, userId, serviceName, "numErrors"
                    new Bacon.Error(err)
                .doAction -> incrIndexCount app, userId, serviceName, "numIndexed"

            return stream
        catch err
            # Catch any uncaught errors
            return new Bacon.Error(err)
)

removeSong = (app, indexId, userId, service, serviceSongId, serviceSongHash, req) ->
    console.log "Remove Song Request", userId, service, request
    Bacon.once("Indexed song")

#Associate an action key with a function to handle the request
module.exports = (worker) ->
    worker.registerHandler(
        actionKeys.indexService,
        (action) ->
            indexService(
                worker,
                action.userId,
                action.service
            )
    )
    worker.registerHandler(
        actionKeys.indexSong,
        (action) ->
            indexSong(
                worker,
                action.userId,
                action.service,
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
                action.service,
                action.serviceSongId,
                change.serviceSongHash,
                action.request
            )
    )