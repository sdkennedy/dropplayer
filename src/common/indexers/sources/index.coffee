dropbox = require './dropbox'

sourceKeys =
    dropbox:'dropbox'

sources = {}
sources[ sourceKeys.dropbox ] = dropbox

authModels = {}
authModels[ sourceKeys.dropbox ] = 'AuthDropbox'

module.exports = { sourceKeys, sources, authModels }