{ requireParamIsUser } = require '../util/auth'
{ indexService } = require '../../indexer/actions'
{ getIndex } = require '../../models/indexes'
{ getUser } = require '../../models/users'
{ getSongs } = require '../../models/songs'

module.exports = (app) ->
    express = app.express
    cache = app.cache()

    #Must be logged in to use all these routes
    express.use "/users/:userId", requireParamIsUser("userId")
    # User Paths
    express.get(
        "/users/:userId"
        (req, res) ->
            getUser app, req.params.userId
                .then (user) -> res.json(user)
    )

    # Indexing
    express.route('/users/:userId/indexes/:service')
        .post (req, res) ->
            indexService app, req.params.userId, req.params.service
                .then (index) -> res.json(index)
        .get (req, res) ->
            getIndex app, req.params.userId, req.params.service
                .then (index) -> res.json(index)

    express.route("/users/:userId/songs")
        .get (req, res) ->
            getSongs app, req.params.userId
                .then (songs) -> res.json songs
