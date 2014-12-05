{ filenameIsMusic } = require '../../util/music'
{ actionKeys } = require '../constants'
Promise = require 'bluebird'
request = require 'request'
_ = require 'underscore'
{ Bacon } = require 'baconjs'

asyncRequest = Promise.promisify request

authorizeRequest = (accessToken, req) ->
    req.headers ?= {}
    req.headers.Authorization = "Bearer #{accessToken}"
    return req

getChanges = do (->
    toChange = (accessToken, result) ->
        [ path, metadata ] = result
        action = if metadata? then actionKeys.indexSong else actionKeys.removeSong
        return {
            action
            fileSize:metadata.bytes
            sourceSongId:path
            sourceSongHash:metadata?.rev
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
            qs:
                path_prefix:"/Drop Play"
                cursor:cursor
        req = authorizeRequest accessToken, req

        asyncRequest(req)
            .spread (response, body) ->
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

    (auth) ->
        Bacon
            .fromBinder (sink) ->
                getChangePage auth.accessToken, auth.rootDir, auth.cursor, sink
                return ->
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
        url:"https://api.dropbox.com/1/media/auto/#{ encodeURIComponent song.contentSourceId}"
    req = authorizeRequest auth.accessToken, req
    asyncRequest(req)
        .spread (response, body) -> JSON.parse(body)

module.exports = { getChanges, getSongUrl }