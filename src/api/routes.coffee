{ requireLogin, requireParamIsUser, requireAuthorizedService } = require './util/auth'
{ buildQueryParams, sendQueryResponse } = require './util/query'
{ indexService, getService } = require '../indexer/actions'
{ getUser } = require '../models/users'
{ getSongs, songTableProperties } = require '../models/songs'
errors = require '../errors'

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

    #Must be logged in to use all these routes
    express.use "/users/:userId", requireParamIsUser("userId")
    # User Paths
    express.get(
        "/users/:userId"
        (req, res) ->
            getUser app, req.params.userId
                .then(
                    (user) -> res.json(user)
                    (err) -> res.json(err)
                )
    )
    express.route("/users/:userId/songs")
        .get (req, res) ->
            queryParams = buildQueryParams app, req, null, songTableProperties
            getSongs app, req.params.userId, queryParams
                .then(
                    (songs) -> sendQueryResponse app, null, songTableProperties, req, res, songs
                    (err) -> res.json(err)
                )

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
