var Bacon, actionKeys, createIndex, indexService, indexSong, removeSong;

actionKeys = require('./constants').actionKeys;

Bacon = require('baconjs').Bacon;

createIndex = require('../models/services').createIndex;

indexService = function(app, service, full) {
  if (full == null) {
    full = false;
  }
  return createIndex(app, service).then(function(index) {
    return app.workerBus().push({
      type: actionKeys.indexService,
      serviceId: service.serviceId,
      full: full
    }, "indexer.indexService." + service.serviceId);
  });
};

indexSong = function(app, userId, serviceId, serviceSongId, serviceSongHash, request, fileSize) {
  return app.workerBus().push({
    type: actionKeys.indexSong,
    userId: userId,
    serviceId: serviceId,
    serviceSongId: serviceSongId,
    serviceSongHash: serviceSongHash,
    request: request,
    fileSize: fileSize
  }, "indexer.indexSong." + userId + "," + serviceId + "," + serviceSongId);
};

removeSong = function(app, userId, serviceId, serviceSongId, serviceSongHash, request) {
  return app.workerBus().push({
    type: actionKeys.removeSong,
    userId: userId,
    serviceId: serviceId,
    serviceSongId: serviceSongId,
    serviceSongHash: serviceSongHash,
    request: request
  }, "indexer.removeSong." + userId + "," + serviceId + "," + serviceSongId);
};

module.exports = {
  indexService: indexService,
  indexSong: indexSong,
  removeSong: removeSong
};
