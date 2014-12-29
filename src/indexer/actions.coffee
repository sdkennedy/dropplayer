{ actionKeys } = require './constants'
{ createIndex } = require '../models/services'

indexService = (app, service, full=false) ->
    createIndex app, service
        .then (index) ->
            app.workerBus().push(
                {
                    type: actionKeys.indexService
                    serviceId:service.serviceId
                    full
                },
                "indexer.indexService.#{service.serviceId}"
            )

indexSong = (app, userId, serviceId, serviceSongId, serviceSongHash, request, fileSize) ->
    app.workerBus().push(
        {
            type:actionKeys.indexSong
            userId
            serviceId
            serviceSongId
            serviceSongHash
            request
            fileSize
        },
        "indexer.indexSong.#{userId},#{serviceId},#{serviceSongId}"
    )

removeSong = (app, userId, serviceId, serviceSongId, serviceSongHash, request) ->
    app.workerBus().push(
        {
            type: actionKeys.removeSong
            userId
            serviceId
            serviceSongId
            serviceSongHash
            request
        },
        "indexer.removeSong.#{userId},#{serviceId},#{serviceSongId}"
    )

indexAlbum = (app, album) ->
    app.workerBus().push(
        {
            type: actionKeys.indexAlbum
            album
        },
        "indexer.indexAlbum.#{album.countId}"
    )

indexAlbums = (app, userId) ->
    app.workerBus().push(
        {
            type: actionKeys.indexAlbums
            userId
        },
        "indexer.indexAlbums.#{userId}"
    )

module.exports = { indexService, indexSong, removeSong, indexAlbum, indexAlbums }