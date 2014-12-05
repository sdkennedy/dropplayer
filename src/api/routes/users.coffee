{ requireParamIsUser, requireSourceAuth } = require '../util/auth'
{ indexSource } = require '../../common/indexers/actions'
{ authModels, sources } = require '../../common/indexers/sources/index'
{ respondToRejection, respondToResolution } = require '../util/promises'
errors = require '../errors'
Promise = require 'bluebird'
module.exports = (app) ->

    { AuthDropbox, User, Song } = app.db().models

    express = app.express

    #Must be logged in to use all these routes
    express.use "/users/:userId", requireParamIsUser("userId")
    # User Paths
    express.get(
        "/users/:userId"
        (req, res) ->
            User
                .find req.params.userId
                .then res.json.bind(res)
    )

    # Start indexing a source
    express.post(
        "/users/:userId/indexes/:source",
        requireSourceAuth(app, "source", "userId"),
        (req, res) ->
            { userId, source } = req.params
            ContentIndex = app.db().model 'ContentIndex'
            ContentIndex
                # Get any existing index
                .getUnfinishedIndex userId, source
                # If no contentIndex is currently running, create one
                .then (existingIndex) ->
                    console.log "existing index", existingIndex
                    if true or not existingIndex?
                        ContentIndex.create UserId:userId, contentSource:source
                    else
                        Promise.reject new errors.IndexRunningError(source, existingIndex)
                # Send indexing request to worker to be processed
                .then (contentIndex) ->
                    console.log "created index", contentIndex
                    indexSource(app, contentIndex.id, userId, source)
                        .return contentIndex
                # Send response
                .then(
                    respondToResolution(res)
                    respondToRejection(res)
                )
    )

    # Get index status of a source

    express.get(
        "/users/:userId/songs"
        (req, res) ->
            { userId } = req.params
            Song
                .findAll where:{ UserId:userId }
                .then(
                    (songs) -> res.json songs
                    respondToRejection(res)
                )
    )
    express.get(
        "/users/:userId/songs/:songId"
        (req, res) ->
            { songId } = req.params
            Song
                .find songId
                .then(
                    (song) -> res.json(song)
                    respondToRejection(res)
                )
    )
    express.get(
        "/users/:userId/songs/:songId/actions/play"
        (req, res) ->
            { userId, songId } = req.params
            authPromise = AuthDropbox.find where:{ UserId:userId }
            Song
                .find songId
                .then (song) ->
                    #Get user's auth entry for the given source
                    Auth = app.db().model authModels[ song.contentSource ]
                    source = sources[ song.contentSource ]
                    Auth
                        .find where:{ UserId:userId }
                        #Get the song url with the source
                        .then (auth) -> source.getSongUrl(auth, song)
                        .then(
                            (url) -> res.json url
                            respondToRejection(res)
                        )
    )