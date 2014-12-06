passport = require 'passport'
DropboxOAuth2Strategy = require('passport-dropbox-oauth2').Strategy
url = require 'url'
_ = require 'underscore'
authDropbox = require '../../common/models/auth_dropbox'

module.exports = (app) ->

    express = app.express
    express.use passport.initialize()
    express.use passport.session()

    # Session is stored in signed cookie so only store the user.id
    passport.serializeUser (id, done) ->  done(null, id)
    passport.deserializeUser (id, done) -> done(null, id)

    # Dropbox Auth
    dropboxCallback = "/auth/dropbox/callback"
    passport.use new DropboxOAuth2Strategy(
        clientID: app.config.AUTH_DROPBOX_CLIENT_ID
        clientSecret: app.config.AUTH_DROPBOX_CLIENT_SECRET
        callbackURL: url.format _.extend({}, app.config.API_EXTERNAL_HOST, pathname:dropboxCallback)
        (accessToken, refreshToken, profile, done) ->
            authDropbox
                .findOrCreate app.db(), accessToken, profile
                .then(
                    (user) -> done null, user.id
                    (err) -> done err, null
                )
    )
    express.get "/auth/dropbox", passport.authenticate('dropbox-oauth2')
    express.get(
        dropboxCallback,
        passport.authenticate('dropbox-oauth2'),
        (req, res) -> res.send("success")
    )