{ actionKeys } = require './constants'
{ Bacon } = require 'baconjs'
indexSource = (app, indexId, userId, source) ->
    app.workerBus().push(
        {
            type: actionKeys.indexSource
            indexId
            userId
            source
        },
        "indexer.indexSource.#{indexId}"
    )

indexSong = (app, indexId, userId, source, sourceSongId, sourceSongHash, request, fileSize) ->
    app.workerBus().push(
        {
            type:actionKeys.indexSong
            indexId
            userId
            source
            sourceSongId
            sourceSongHash
            request
            fileSize
        },
        "indexer.indexSong.#{indexId},#{sourceSongHash}"
    )

removeSong = (app, indexId, userId, source, sourceSongId, sourceSongHash, request) ->
    app.workerBus().push(
        {
            type: actionKeys.removeSong
            indexId
            userId
            source
            sourceSongId
            request
        },
        "indexer.removeSong.#{indexId},#{sourceSongHash}"
    )

module.exports = { indexSource, indexSong, removeSong }