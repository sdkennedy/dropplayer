{ requireLogin, requireParamIsUser, requireAuthorizedService } = require './util/auth'
{ buildGetCollectionEndpoint } = require './util/get_collection'
{ buildGetEntityEndpoint } = require './util/get_entity'
{ indexService, indexAlbums } = require '../indexer/actions'
{ scanUsers, getUser, usersTableProperties } = require '../models/users'
{ songTableProperties, querySongs, getSong } = require '../models/songs'
{ getAlbum, queryAlbums } = require '../models/song_albums'
{ getPrimaryArtist, queryPrimaryArtists } = require '../models/song_artists'
{ getSongCountPrefix } = require '../models/song_counts'
{ getPrimaryGenre, queryPrimaryGenres } = require '../models/song_genres'
{ queryCounts, countsTableProperties } = require '../models/counts'
{ buildApiUrl } = require './util/url'
{ queryAll } = require '../models/util'
errors = require '../errors'
_ = require 'lodash'
url = require 'url'

module.exports = (app) ->
    express = app.express

    express.get(
        "/env"
        requireLogin
        (req, res) ->
            getUser app, req.user
                .then(
                    (user) -> res.json app.config
                    (err) -> res.json err
                )
    )    

    express.get(
        "/session"
        requireLogin
        (req, res) ->
            getUser app, req.user
                .then(
                    (user) -> res.json user:buildApiUrl(app, pathname:"/users/#{user.userId}")
                    (err) -> res.json(err)
                )
    )

    express.get(
        "/users"
        (req, res) ->
            scanUsers app
                .then(
                    (user) -> res.json user
                    (err) -> res.json err
                )
    )

    #Must be logged in to use all these routes
    express.use "/users/:userId", requireParamIsUser("userId")
    
    buildGetEntityEndpoint app, usersTableProperties, getUser, "users"

    buildGetCollectionEndpoint app, "users", "songs", songTableProperties, querySongs
    buildGetEntityEndpoint app, songTableProperties, getSong, "users", "songs"

    buildGetCollectionEndpoint app, "users", "albums", countsTableProperties, queryAlbums
    buildGetEntityEndpoint app, countsTableProperties, getAlbum, "users", "albums"

    express
        .route '/users/:userId/albums/actions/index'
        .post (req, res) ->
            indexAlbums app, req.params.userId, true
                .then(
                    (service) -> res.json(service)
                    (err) -> res.json(err)
                )

        

    buildGetCollectionEndpoint app, "users", "primaryArtists", countsTableProperties, queryPrimaryArtists
    buildGetEntityEndpoint app, countsTableProperties, getPrimaryArtist, "users", "primaryArtists"

    buildGetCollectionEndpoint app, "users", "primaryGenres", countsTableProperties, queryPrimaryGenres
    buildGetEntityEndpoint app, countsTableProperties, getPrimaryGenre, "users", "primaryGenres"
            
    # Indexing
    # Verifies logged in users has access to serviceId and attaches service to request
    express.use "/services/:serviceId", requireAuthorizedService(app)

    express
        .route '/services/:serviceId'
        .get (req, res) -> res.json req.service

    express
        .route '/services/:serviceId/actions/index'
        .post (req, res) ->
            indexService app, req.service, true
                .then(
                    (service) -> res.json(service)
                    (err) -> res.json(err)
                )
