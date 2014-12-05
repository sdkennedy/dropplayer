actions = require './actions'
{ actionKeys } = require './constants'
{ sources, authModels } = require './sources/index'
dropbox = require './sources/dropbox'
Promise = require 'bluebird'
{ Bacon } = require 'baconjs'
request = require 'request'
musicMetadata = require 'musicmetadata'

indexSource = (app, indexId, userId, sourceName) ->
    if not sources[sourceName]?
        Bacon.once new Bacon.Error("No indexer for source #{sourceName}")

    source = sources[sourceName]
    Auth = app.db().model authModels[sourceName]

    console.log "indexSource", indexId, userId, sourceName
    Bacon
        .fromPromise Auth.find(where:{ UserId:userId })
        .flatMap source.getChanges
        .flatMap (change) ->
            console.log "change", change
            if actions[change.action]?
                action = actions[change.action]
                # Push index / remove song action on to SQS
                Bacon.fromPromise action(
                    app,
                    indexId,
                    userId,
                    sourceName,
                    change.sourceSongId,
                    change.sourceSongHash,
                    change.request,
                    change.fileSize
                )
            else
                Bacon.once new Bacon.Error("Could no find indexer action for #{change.action}")
        #Bring all changes back together into a single event when complete
        .fold(null, ->)
        .toEventStream()

indexSong = do (->
    getMetadata = (req, fileSize) ->
        return new Bacon.fromBinder((sink)->
            parser = musicMetadata(
                reqStream = request(req)
                fileSize:fileSize
            )
            reqStream.on 'error', (err) -> console.log 'reqest error', err
            parser.on 'metadata', (result) ->
                sink new Bacon.Next(result)
            parser.on 'done', (err) ->
                reqStream.destroy()
                if err?
                    console.error err
                    sink new Bacon.Error(err)
                sink new Bacon.End()

            return -> reqStream.destroy()
        )

    createSong = (app, userId, source, sourceSongId, sourceSongHash, metadata) ->
        Song = app.db().model 'Song'
        data =
            # Who owns it
            UserId: userId
            # Where is came from
            contentSource:source
            contentSourceId:sourceSongId
            contentSourceHash:sourceSongHash
            # Metadata columns
            album: metadata.album
            genre: metadata.genre
            title: metadata.title
            artist: metadata.artist
            discnumber: metadata.disk
            tracknumber: metadata.track
            albumartistsort: metadata.albumartist
        Bacon.fromPromise Song.create(data)

    existingSong = (app, userId, source, sourceSongId, sourceSongHash) ->
        Song = app.db().model 'Song'
        where =
            UserId:userId
            contentSource:source
            contentSourceId:sourceSongId
        where.contentSourceHash = sourceSongHash if sourceSongHash?

        Bacon.fromPromise Song.find({where})

    (app, indexId, userId, source, sourceSongId, sourceSongHash, req, fileSize) ->
        console.log "indexSong", indexId, userId, source, sourceSongId, sourceSongHash, req, fileSize
        existingSong(app, userId, source, sourceSongId, sourceSongHash)
            .flatMap (existingSong) ->
                #Only continue if song is nonexistant or hash different
                if existingSong? then Bacon.never() else Bacon.once()
            .flatMap -> getMetadata(req, fileSize)
            .flatMap (metadata) -> createSong(app, userId, source, sourceSongId, sourceSongHash, metadata)
)

removeSong = (app, indexId, userId, source, sourceSongId, sourceSongHash, req) ->
    console.log "Remove Song Request", indexId, userId, source, request
    Bacon.once("Indexed song")

module.exports = { indexSource, indexSong, removeSong }