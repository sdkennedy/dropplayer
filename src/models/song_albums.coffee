rp = require 'request-promise'
request = require 'request'
url = require 'url'
moment = require 'moment'
Promise = require 'bluebird'
imagesize = require 'imagesize'
_ = require 'lodash'
imagesizeAsync = Promise.promisify imagesize
{ incrCount, queryCounts, getCount } = require './counts'
{ getSongCountKey, getSongCountPrefix } = require './song_counts'

getAlbum = getCount

queryAlbums = (app, userId, query) ->
    prefix = getSongCountPrefix("album")
    queryCounts app, userId, prefix, query

getAlbumsByIds = (app, userId, ids) ->

putAlbumBySong = (app, song) ->
    countKey = getSongCountKey(song, 'album')
    album = {
        album:song.album
        primaryArtist:song.primaryArtist
        pictures:song.pictures ? []
    }
    incrCount app, song.userId, countKey, album
        .then -> _.extend { countId:countKey, userId:song.userId }, album

updateAlbum = (app, data) ->
    AttributeUpdates = {}
    for key, val of (data ? {})
        continue if ["userId", "countId"].indexOf(key) isnt -1
        AttributeUpdates[key] = { Action:"PUT", Value:val }

    app.dbDoc().updateItemAsync(
        TableName: app.config.DYNAMODB_TABLE_COUNTS
        Key:{ userId:data.userId, countId:data.countId }
        AttributeUpdates:AttributeUpdates
    )

module.exports = { getAlbum, queryAlbums, putAlbumBySong, updateAlbum }