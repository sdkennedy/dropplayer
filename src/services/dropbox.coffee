{ filenameIsMusic } = require '../util/music'
{ actionKeys } = require '../indexer/constants'
Promise = require 'bluebird'
request = require 'request'
_ = require 'underscore'
{ Bacon } = require 'baconjs'
passport = require 'passport'
url = require 'url'
DropboxOAuth2Strategy = require('passport-dropbox-oauth2').Strategy
{ getCredentialsOrCreate } = require '../models/credentials'

asyncRequest = Promise.promisify request

serviceName = "dropbox"

getChanges = do (->
    toChange = (accessToken, result) ->
        [ path, metadata ] = result
        action = if metadata? then actionKeys.indexSong else actionKeys.removeSong
        return {
            action
            fileSize:metadata.bytes
            serviceSongId:path
            serviceSongHash:metadata?.rev
            request:
                url:"https://api-content.dropbox.com/1/files/auto#{ encodeURIComponent path }"
                headers:
                    Authorization: "Bearer #{accessToken}"
        }
    getChangePage = (accessToken, rootDir, cursor, sink) ->
        #Build request
        req =
            method:"POST"
            url:"https://api.dropbox.com/1/delta"
            headers:
                Authorization: "Bearer #{accessToken}"
            qs:
                path_prefix:"/Drop Play"
                cursor:cursor

        asyncRequest(req)
            .spread (response, body) ->
                try
                    data = JSON.parse(body)
                    console.log(data) if not data?.entries?
                    changes = (data?.entries ? [])
                        .filter (result) -> filenameIsMusic result[0]
                        .map (result) -> toChange accessToken, result
                        .forEach (change) -> sink new Bacon.Next({ change })
                    if data.has_more
                        getChangePage(accessToken, rootDir, data.cursor, sink)
                    else
                        sink new Bacon.Next({ cursor:data.cursor })
                        sink new Bacon.End()
                catch err
                    # Catch any uncaught errors
                    sink new Bacon.Error(err)
                    sink new Bacon.End()

    return ( credentials ) ->
        Bacon
            .fromBinder (sink) ->
                getChangePage credentials.accessToken, credentials.rootDir, credentials.cursor, sink
                return -> #Cleanup function
            .flatMap (item) ->
                if item.change
                    return Bacon.once item.change
                else if item.cursor
                    #Update cursor
                    #auth.item.cursor = item.cursor

                    #Prevent stream from ending until auth is saved
                    return Bacon.fromPromise( auth.save() ).flatMap -> Bacon.never()
                else
                    return Bacon.never()

)

getSongUrl = ( auth, song ) ->
    req =
        methos:"POST"
        url:"https://api.dropbox.com/1/media/auto/#{ encodeURIComponent song.serviceSongId }"
    req = authorizeRequest auth.accessToken, req
    asyncRequest(req).spread (response, body) -> JSON.parse(body)

initRoutes = do (->
    createCredentials = (accessToken, profile) ->
        {
            providerId:"dropbox.#{profile.id}"
            service:"dropbox"
            displayName:profile.displayName
            email:profile.emails?[0]?.value
            accessToken:accessToken
            rootDir:null
            cursor:null
        }
    return (app) ->
        # Dropbox Auth
        dropboxCallback = "/auth/dropbox/callback"
        passport.use new DropboxOAuth2Strategy(
            clientID: app.config.AUTH_DROPBOX_CLIENT_ID
            clientSecret: app.config.AUTH_DROPBOX_CLIENT_SECRET
            callbackURL: url.format _.extend({}, app.config.API_EXTERNAL_HOST, pathname:dropboxCallback)
            (accessToken, refreshToken, profile, done) ->
                credentials = createCredentials accessToken, profile
                getCredentialsOrCreate app, credentials
                    .then(
                        (credentials) -> done null, credentials.userId
                        (err) -> done err, null
                    )
        )
        app.express.get "/auth/dropbox", passport.authenticate('dropbox-oauth2')
        app.express.get(
            dropboxCallback,
            passport.authenticate('dropbox-oauth2'),
            (req, res) ->
                res.json(
                    user:url.format _.extend(
                        {},
                        app.config.API_EXTERNAL_HOST,
                        pathname:"/users/#{req.user}"
                    )
                )
        )
)

module.exports = { serviceName, getChanges, getSongUrl, initRoutes }