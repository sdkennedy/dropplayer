{ requireLogin, requireParamIsUser, requireAuthorizedService } = require '../util/auth'
{ indexService, getService } = require '../../indexer/actions'
{ getUser } = require '../../models/users'
{ getSongs } = require '../../models/songs'
errors = require '../../errors'

module.exports = (app) ->
    express = app.express
    cache = app.cache()

    express.get(
        "/session"
        requireLogin
        (req, res) ->
            getUser app, req.user
                .then (user) -> res.json(user)
    )

    #Must be logged in to use all these routes
    express.use "/users/:userId", requireParamIsUser("userId")
    # User Paths
    express.get(
        "/users/:userId"
        (req, res) ->
            getUser app, req.params.userId
                .then (user) -> res.json(user)
    )
    express.route("/users/:userId/songs")
        .get (req, res) ->
            getSongs app, req.params.userId
                .then (songs) -> res.json songs


    # Indexing

    # Verifies logged in users has access to serviceId and attaches service to request
    express.use "/services/:serviceId", requireAuthorizedService(app)

    express.route('/services/:serviceId')
        .get (req, res) -> res.json(req.service)

    express.route('/services/:serviceId/actions/index')
        .post (req, res) ->
            indexService app, req.service, true
                .then (service) -> res.json(service)
