{ incrCount, queryCounts, getCount } = require './counts'
{ getSongCountKey, getSongCountPrefix } = require './song_counts'

getPrimaryGenre = getCount

queryPrimaryGenres = (app, userId, query) ->
    prefix = getSongCountPrefix("primaryGenre")
    queryCounts app, userId, prefix, query

putPrimaryGenreBySong = (app, song) ->
    countKey = getSongCountKey(song, 'primaryGenre')
    data = { primaryGenre:song.primaryGenre }
    incrCount app, song.userId, countKey, data

module.exports = { getPrimaryGenre, queryPrimaryGenres, putPrimaryGenreBySong }