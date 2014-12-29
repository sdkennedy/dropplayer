rp = require 'request-promise'
request = require 'request'
urlFormat = require('url').format
moment = require 'moment'
Promise = require 'bluebird'
imagesize = require 'imagesize'
_ = require 'lodash'
imagesizeAsync = Promise.promisify imagesize
{ getAlbum, updateAlbum } = require '../../models/song_albums'

getAlbumReleaseGroupId = (album) ->
    return Promise.resolve( album.releaseGroupMbid ) if album.releaseGroupMbid?
    query = []
    query.push("release:\"#{ encodeURIComponent album.album }\"") if album.album?
    query.push("artist:\"#{ encodeURIComponent album.primaryArtist }\"") if album.primaryArtist?
    if query.length > 0
        rp(
            urlFormat(
                hostname:"musicbrainz.org"
                protocol:"http:"
                slashes:true
                pathname: "/ws/2/release-group/"
                query:
                    query: query.join(" AND ")
                    fmt: "json"
            )
        ).then(
            (resp) -> 
                releaseGroup = JSON.parse( resp )?["release-groups"]?[0] ? []
                Promise.resolve releaseGroup?.id
            (err) -> Promise.resolve null
        )
    else
        Promise.resolve null

getCoverArt = do (->
    buildThumbnail = (url) ->
        imagesizeAsync( req = request(url) )
            .then(
                (dimensions) ->
                    req.abort()
                    return {
                        url: url
                        width: dimensions.width
                        height: dimensions.height
                        type: dimensions.format
                    }
                (err) -> { url }
            )
    return (album) ->
        if album.releaseGroupMbid?
            rp("http://coverartarchive.org/release-group/#{ album.releaseGroupMbid }")
                .then(
                    (resp) ->
                        urls = _.values( JSON.parse( resp )?.images?[0].thumbnails ? {} )
                        promises = urls.map buildThumbnail
                        Promise.all promises
                    (err) ->
                        if err?.statusCode is 404
                            return { pictures:[] }
                        else
                            Promise.reject err
                ).then (pictures) -> return { pictures }
        else
            Promise.resolve(album)
)

getReleaseInfo = (album) ->
    return Promise.resolve({}) if album.releaseMbid?
    query = []
    query.push("release:\"#{ encodeURIComponent album.album }\"") if album.album?
    query.push("artist:\"#{ encodeURIComponent album.primaryArtist }\"") if album.primaryArtist?
    if query.length > 0
        url = urlFormat(
            hostname:"musicbrainz.org"
            protocol:"http:"
            slashes:true
            pathname: "/ws/2/release/"
            query:
                query: query.join(" AND ")
                fmt: "json" 
        )
        rp url
            .then(
                (resp) -> 
                    releases = JSON.parse( resp )?.releases ? []
                    releases = releases.filter (release) -> release.date?
                    release = releases?[0]
                    if release?
                        return {
                            releaseMbid: release.id
                            releaseDate: moment( release.date ).format( "YYYY-MM-DD" )
                        }
                    else
                        return {}
                (err) -> {}
            )
    else
        Promise.resolve {}

getReleaseDate = () ->

indexAlbum = (app, data) ->
    console.log "indexAlbum", data
    return getAlbum( app, data.userId, data.countId )
        .then (album) -> if album? then album else data
        .then (album) -> (
            Promise.all([
                #Get release group id
                getAlbumReleaseGroupId(album)
                    .then (releaseGroupMbid) ->
                        console.log "getAlbumReleaseGroupId(#{ album.countId })", releaseGroupMbid
                        album.releaseGroupMbid = releaseGroupMbid
                        if releaseGroupMbid? and album.pictures.length is 0
                            #Get Cover Art
                            getCoverArt(album).then (partial) -> 
                                console.log "getCoverArt(#{ album.countId })", partial
                                _.extend album, partial
                        else
                            Promise.resolve album
                #Get Release and Release Date
                getReleaseInfo(album).then (partial) -> 
                    console.log "getReleaseInfo(#{ album.countId })", partial
                    _.extend album, partial
            ]).then -> album
        ).then (album) -> 
            console.log "updateAlbum(#{ album.countId })", album
            updateAlbum app, album

module.exports = indexAlbum