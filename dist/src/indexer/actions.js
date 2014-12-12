var Bacon, actionKeys, createIndex, indexService, indexSong, removeSong;

actionKeys = require('./constants').actionKeys;

Bacon = require('baconjs').Bacon;

createIndex = require('../models/indexes').createIndex;

indexService = function(app, userId, service) {
  return createIndex(app, userId, service).then(function(index) {
    app.workerBus().push({
      type: actionKeys.indexService,
      userId: userId,
      service: service
    }, "indexer.indexService." + userId + "," + service);
    return index;
  });
};

indexSong = function(app, userId, service, serviceSongId, serviceSongHash, request, fileSize) {
  return app.workerBus().push({
    type: actionKeys.indexSong,
    userId: userId,
    service: service,
    serviceSongId: serviceSongId,
    serviceSongHash: serviceSongHash,
    request: request,
    fileSize: fileSize
  }, "indexer.indexSong." + userId + "," + service + "," + serviceSongHash);
};

removeSong = function(app, userId, service, serviceSongId, serviceSongHash, request) {
  return app.workerBus().push({
    type: actionKeys.removeSong,
    userId: userId,
    service: service,
    serviceSongId: serviceSongId,
    serviceSongHash: serviceSongHash,
    request: request
  }, "indexer.removeSong." + userId + "," + service + "," + serviceSongHash);
};

module.exports = {
  indexService: indexService,
  indexSong: indexSong,
  removeSong: removeSong
};
