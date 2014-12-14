{ actionKeys } = require './constants'
{ Bacon } = require 'baconjs'
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

module.exports = { indexService, indexSong, removeSong }