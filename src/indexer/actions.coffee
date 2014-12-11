{ actionKeys } = require './constants'
{ Bacon } = require 'baconjs'
{ createIndex } = require '../models/indexes'
indexService = (app, userId, service) ->
    createIndex app, userId, service
        .then (index) ->
            app.workerBus().push(
                {
                    type: actionKeys.indexService
                    userId
                    service
                },
                "indexer.indexService.#{userId},#{service}"
            )
            return index

indexSong = (app, userId, service, serviceSongId, serviceSongHash, request, fileSize) ->
    app.workerBus().push(
        {
            type:actionKeys.indexSong
            userId
            service
            serviceSongId
            serviceSongHash
            request
            fileSize
        },
        "indexer.indexSong.#{userId},#{service},#{serviceSongHash}"
    )

removeSong = (app, userId, service, serviceSongId, serviceSongHash, request) ->
    app.workerBus().push(
        {
            type: actionKeys.removeSong
            userId
            service
            serviceSongId
            serviceSongHash
            request
        },
        "indexer.removeSong.#{userId},#{service},#{serviceSongHash}"
    )

module.exports = { indexService, indexSong, removeSong }