{ Bacon } = require 'baconjs'
Promise = require 'bluebird'
musicMetadata = require 'musicmetadata'
request = require 'request'
_ = require 'lodash'
{ indexAlbum } = require '../actions'

{ incrIndexCount } = require '../../models/services'
{ getSongId, putSong, getSong } = require '../../models/songs'
{ putAlbumBySong } = require '../../models/song_albums'
{ putPrimaryArtistBySong } = require '../../models/song_artists'
{ putPrimaryGenreBySong } = require '../../models/song_genres'
{ saveMetadataPictures } = require '../../models/song_cover_art'

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

            # Trim strings
            newVal = newVal.trim() if typeof newVal is "string"

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
                sink new Bacon.End()
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
        songId = getSongId serviceId, serviceSongId
        pictures = metadata.picture ? []

        data =
            # Who owns it
            userId: userId
            songId: songId
            # Where is came from
            serviceId:serviceId
            serviceSongId:serviceSongId
            serviceSongHash:serviceSongHash

            # Metadata columns
            title: metadata.title
            primaryArtist: metadata.artist?[0]
            artist: metadata.artist
            album: metadata.album
            primaryGenre: metadata.genre?[0]
            genre: metadata.genre
            discNumber: metadata.disk?.no
            discNumberTotal: metadata.disk?.of
            trackNumber: metadata.track?.no
            trackNumberTotal: metadata.track?.of
            primaryAlbumArtistSort: metadata.albumartist?[0]
            albumArtistSort: metadata.albumartist

            pictures: saveMetadataPictures app, data, metadata.picture
            
        return Bacon.fromPromise Promise.props( putSong( app, data ) )
    catch err
        return new Bacon.Error err

createSongAggregates = (app, song) ->
    streams = []
    streams.push createAlbum app, song
    streams.push Bacon.fromPromise putPrimaryArtistBySong(app, song) if song.primaryArtist?
    streams.push Bacon.fromPromise putPrimaryGenreBySong(app, song) if song.primaryGenre?
    Bacon.zipWith streams, -> Bacon.once song

createAlbum = (app, song) ->
    if song.album?
        Bacon.fromPromise putAlbumBySong(app, song)
            .flatMap (album) ->
                indexAlbum app, album
    else
        Bacon.never()

indexSong = (app, userId, serviceId, serviceSongId, serviceSongHash, req, fileSize) ->
    #console.log "indexSong(#{userId}, #{serviceId}, #{serviceSongId})"
    try
        songId = getSongId serviceId, serviceSongId
        return Bacon.fromPromise getSong(app, userId, songId)
            #Only continue if song is nonexistant or hash different
            .flatMap (existingSong) ->
                return Bacon.once()
                needsUpdate = not existingSong? or existingSong.serviceSongHash isnt serviceSongHash
                if needsUpdate then Bacon.once() else Bacon.never()
            # Get song metadata
            .flatMap -> getMetadata req, fileSize
            # Create song in database
            .flatMap (metadata) -> createSong app, userId, serviceId, serviceSongId, serviceSongHash, metadata
            # Create song aggregates (artist, album)
            .flatMap (song) -> createSongAggregates app, song
            # Log how many songs have errors
            .mapError (err) ->
                incrIndexCount app, serviceId, "numErrors"
                new Bacon.Error(err)
            # Log how many songs were indexed correctly
            .doAction -> incrIndexCount app, serviceId, "numIndexed"
    catch err
        # Catch any uncaught errors
        return new Bacon.Error err

module.exports = indexSong