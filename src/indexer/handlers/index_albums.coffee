{ indexAlbum } = require '../actions'
{ queryAlbums } = require '../../models/song_albums'
{ queryAll } = require '../../models/util'

indexAlbums = (app, userId) ->
    queryAll app, (app, params) -> queryAlbums app, userId, params
        .flatMap (album) ->
            indexAlbum app, album
        .fold [], (acc, val) -> 
            acc.push val
            return acc

module.exports = indexAlbums