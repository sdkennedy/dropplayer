var filenameIsMusic, validExtensions;

validExtensions = [".mp3"];

filenameIsMusic = function(path) {
  return typeof path === "string" && validExtensions.indexOf(path.substr(-4)) !== -1;
};

module.exports = {
  filenameIsMusic : filenameIsMusic 
};
