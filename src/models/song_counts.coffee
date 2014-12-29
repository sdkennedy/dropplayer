module.exports.getSongCountPrefix = (key) -> "songs.#{key}"
module.exports.getSongCountKey = (song, key) -> "songs.#{key}.#{song[key]}"