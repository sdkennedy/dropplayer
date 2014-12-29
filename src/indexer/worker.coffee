
# Indexer Libraries
{ actionKeys } = require './constants'
indexServiceHandler = require './handlers/index_service'
indexSongHandler = require './handlers/index_song'
removeSongHandler = require './handlers/remove_song'
indexAlbumHandler = require './handlers/index_album'
indexAlbumsHandler = require './handlers/index_albums'

#Associate an action key with a function to handle the request
module.exports = (worker) ->
    worker.registerHandler(
        actionKeys.indexService,
        (action) ->
            indexServiceHandler(
                worker,
                action.serviceId
                action.full
            )
    )
    worker.registerHandler(
        actionKeys.indexSong,
        (action) ->
            indexSongHandler(
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
            removeSongHandler(
                worker,
                action.userId,
                action.serviceId,
                action.serviceSongId,
                change.serviceSongHash,
                action.request
            )
    )
    worker.registerHandler(
        actionKeys.indexAlbum,
        (action) ->
            indexAlbumHandler(
                worker,
                action.album
            )
    )
    worker.registerHandler(
        actionKeys.indexAlbums,
        (action) ->
            indexAlbumsHandler(
                worker,
                action.userId
            )
    )