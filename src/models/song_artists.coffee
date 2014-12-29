{ incrCount, queryCounts, getCount } = require './counts'
{ getSongCountKey, getSongCountPrefix } = require './song_counts'

queryPrimaryArtists = (app, userId, query) ->
    prefix = getSongCountPrefix "primaryArtist"
    queryCounts app, userId, prefix, query

putPrimaryArtistBySong = (app, song) ->
    countKey = getSongCountKey song, 'primaryArtist'
    data = { primaryArtist:song.primaryArtist }
    incrCount app, song.userId, countKey, data

updateLatestAlbum = (app, song) ->
    # todo: need album date first
    ###
    countId = getSongCountKey song, 'primaryArtist'
    app.dbDoc().putItemAsync(
        TableName: app.config.DYNAMODB_TABLE_COUNTS
        Key:
            userId:song.userId
            countId:countId
        AttributeUpdates:AttributeUpdates
    )
    ###

getPrimaryArtist = getCount
    

module.exports = { getPrimaryArtist, queryPrimaryArtists, putPrimaryArtistBySong }