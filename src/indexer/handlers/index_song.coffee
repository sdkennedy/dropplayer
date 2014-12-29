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
    return new Promise ( resolve, reject )->
        try
            parser = musicMetadata(
                #Request can't be created outside of musicMetadata because stream will start sending data immediately
                reqStream = request(req)
                fileSize:fileSize
            )
            reqStream.on 'error', (err) ->
                console.log 'reqest error', err
                reject err
            parser.on 'metadata', (result) -> resolve sanitizeMetadata(result)
            parser.on 'done', (err) ->
                reqStream.destroy()
                reject(err) if err?
        catch err
            reject err

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
            
        Promise.props( putSong( app, data ) )
    catch err
        Promise.reject err

createSongAggregates = (app, song) ->
    promises = []
    promises.push createAlbum app, song
    promises.push putPrimaryArtistBySong(app, song) if song.primaryArtist?
    promises.push putPrimaryGenreBySong(app, song) if song.primaryGenre?
    Promise.all(promises).then -> song

createAlbum = (app, song) ->
    if song.album?
        putAlbumBySong(app, song).then (album) -> indexAlbum app, album
    else
        Promise.resolve song

indexSong = (app, userId, serviceId, serviceSongId, serviceSongHash, req, fileSize) ->
    console.log "indexSong(#{userId}, #{serviceId}, #{serviceSongId})"
    try
        songId = getSongId serviceId, serviceSongId
        getSong(app, userId, songId)
            .then (existingSong) ->
                console.log "indexSong.songExists(#{userId}, #{serviceId}, #{serviceSongId}) = #{!!existingSong}"
                return existingSong if existingSong?
                return getMetadata req, fileSize
                    .then (metadata) ->
                        console.log "indexSong.metadata(#{userId}, #{serviceId}, #{serviceSongId}) = #{ metadata?.title }"
                        createSong app, userId, serviceId, serviceSongId, serviceSongHash, metadata
                    .then (song) -> createSongAggregates app, song
                    .tap (song) -> incrIndexCount app, serviceId, "numIndexed"
                    .catch (err) ->
                            incrIndexCount app, serviceId, "numErrors"
                            Promise.reject err
    catch err
        # Catch any uncaught errors
        Promise.reject err

module.exports = indexSong