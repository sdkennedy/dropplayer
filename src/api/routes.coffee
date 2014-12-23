{ requireLogin, requireParamIsUser, requireAuthorizedService } = require './util/auth'
{ buildQueryParams, sendQueryResponse } = require './util/query'
{ indexService, getService } = require '../indexer/actions'
{ getUsers, getUser } = require '../models/users'
{ songTableProperties, getSongs, getAlbums, getArtists, getGenres } = require '../models/songs'
{ getCounts, countsTableProperties } = require '../models/counts'
errors = require '../errors'
_ = require 'underscore'
url = require 'url'

buildSongCountUrl = (app, req, key, result) ->
    query = _.extend {}, req.query
    query[key] = result.displayName
    result.songsUrl = url.format _.extend(
        {},
        app.config.API_EXTERNAL_HOST,
        pathname:"/users/#{req.params.userId}/songs"
        query:query
    )
    return result

createSongCountHandler = (app, key) ->
    (req, res) ->
        queryParams = buildQueryParams app, req, null, countsTableProperties
        getCounts app, req.params.userId, "songs.#{key}", queryParams
            .then(
                (results) -> 
                    results.Items = results.Items.map (result) -> buildSongCountUrl app, req, key, result    
                    sendQueryResponse app, null, countsTableProperties, req, res, results
                (err) -> res.json err
            )

module.exports = (app) ->
    express = app.express

    express.get(
        "/session"
        requireLogin
        (req, res) ->
            getUser app, req.user
                .then(
                    (user) -> res.json(user)
                    (err) -> res.json(err)
                )

    )

    express.get(
        "/users"
        (req, res) ->
            getUsers app
                .then(
                    (user) -> res.json user
                    (err) -> res.json err
                )
    )

    #Must be logged in to use all these routes
    express.use "/users/:userId", requireParamIsUser("userId")
    # User Paths
    express.get(
        "/users/:userId"
        (req, res) ->
            getUser app, req.params.userId
                .then(
                    (user) -> res.json user
                    (err) -> res.json err
                )
    )
    express.route("/users/:userId/songs")
        .get (req, res) ->
            queryParams = buildQueryParams app, req, null, songTableProperties
            getSongs app, req.params.userId, queryParams
                .then(
                    (songs) -> sendQueryResponse app, null, songTableProperties, req, res, songs
                    (err) -> res.json err
                )

    express.get "/users/:userId/songs/albums", createSongCountHandler( app, 'album' )
    express.get "/users/:userId/songs/primaryArtist", createSongCountHandler( app, 'primaryArtist' )
    express.get "/users/:userId/songs/primaryGenre", createSongCountHandler( app, 'primaryGenre' )
            
    # Indexing

    # Verifies logged in users has access to serviceId and attaches service to request
    express.use "/services/:serviceId", requireAuthorizedService(app)

    express.route('/services/:serviceId')
        .get (req, res) -> res.json(req.service)

    express.route('/services/:serviceId/actions/index')
        .post (req, res) ->
            indexService app, req.service, true
                .then(
                    (service) -> res.json(service)
                    (err) -> res.json(err)
                )
