{ Bacon } = require 'baconjs'

songs = require '../../models/songs'
{ getSongId } = songs
removeSongEntity = songs.removeSong

removeSong = (app, userId, serviceId, serviceSongId, serviceSongHash, req) ->
    console.log "removeSong(#{userId}, #{serviceId}, #{serviceSongId})"
    songId = getSongId serviceId, serviceSongId
    Bacon.fromPromise removeSongEntity app, userId, songId