{ actionKeys } = require './constants'
handlers = require './handlers'

#Decodes SQS message passing the right parameters to the handler function

module.exports = (worker) ->
    worker.registerHandler(
        actionKeys.indexSource,
        (action) ->
            handlers.indexSource(
                worker,
                action.indexId
                action.userId,
                action.source
            )
    )
    worker.registerHandler(
        actionKeys.indexSong,
        (action) ->
            handlers.indexSong(
                worker,
                action.indexId,
                action.userId,
                action.source,
                action.sourceSongId,
                action.sourceSongHash,
                action.request,
                action.fileSize
            )
    )
    worker.registerHandler(
        actionKeys.removeSong,
        (action) ->
            handlers.removeSong(
                worker,
                action.indexId,
                action.userId,
                action.source,
                action.sourceSongId,
                change.sourceSongHash,
                action.request
            )
    )