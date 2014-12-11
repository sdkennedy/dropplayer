validExtensions = [ ".mp3" ]
filenameIsMusic = (path) -> 
    typeof path is "string" and validExtensions.indexOf( path.substr(-4) ) isnt -1

module.exports = { filenameIsMusic }