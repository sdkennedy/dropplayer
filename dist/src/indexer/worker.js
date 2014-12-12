var Bacon, Promise, actionKeys, actions, getCredentials, getSong, getSongId, getUser, incrIndexCount, indexService, indexSong, musicMetadata, putSong, removeSong, request, services, _ref;

getUser = require('../models/users').getUser;

getCredentials = require('../models/credentials').getCredentials;

_ref = require('../models/songs'), getSongId = _ref.getSongId, putSong = _ref.putSong, getSong = _ref.getSong;

incrIndexCount = require('../models/indexes').incrIndexCount;

services = require('../services/index');

actions = require('./actions');

actionKeys = require('./constants').actionKeys;

Bacon = require('baconjs').Bacon;

Promise = require('bluebird');

request = require('request');

musicMetadata = require('musicmetadata');

indexService = (function() {
  var callChangeAction;
  callChangeAction = function(app, userId, serviceName, change) {
    var action, err;
    try {
      if (actions[change.action] != null) {
        action = actions[change.action];
        return Bacon.fromPromise(action(app, userId, serviceName, change.serviceSongId, change.serviceSongHash, change.request, change.fileSize));
      } else {
        return new Bacon.Error("Could no find indexer action for " + change.action);
      }
    } catch (_error) {
      err = _error;
      return new Bacon.Error(err);
    }
  };
  return function(app, userId, serviceName) {
    var err;
    try {
      if (services[serviceName] == null) {
        return new Bacon.Error("No indexer for service " + serviceName);
      }
      console.log("indexService", userId, serviceName);
      return Bacon.fromPromise(getUser(app, userId)).flatMap(function(user) {
        if (user != null) {
          return Bacon.fromPromise(getCredentials(app, user.services[serviceName]));
        } else {
          return new Bacon.Error("");
        }
      }).flatMap(function(credentials) {
        return services[serviceName].getChanges(credentials);
      }).doAction(function() {
        return incrIndexCount(app, userId, serviceName, "numFound");
      }).flatMap(function(change) {
        return callChangeAction(app, userId, serviceName, change);
      }).fold(null, function() {}).toEventStream();
    } catch (_error) {
      err = _error;
      return Bacon.Error(err);
    }
  };
})();

indexSong = (function() {
  var createSong, getMetadata;
  getMetadata = function(req, fileSize) {
    return new Bacon.fromBinder(function(sink) {
      var err, parser, reqStream;
      try {
        parser = musicMetadata(reqStream = request(req), {
          fileSize: fileSize
        });
        reqStream.on('error', function(err) {
          return console.log('reqest error', err);
        });
        parser.on('metadata', function(result) {
          return sink(new Bacon.Next(result));
        });
        return parser.on('done', function(err) {
          reqStream.destroy();
          if (err != null) {
            console.error(err);
            sink(new Bacon.Error(err));
          }
          return sink(new Bacon.End());
        });
      } catch (_error) {
        err = _error;
        sink(new Bacon.Error(err));
        return sink(new Bacon.End());
      } finally {
        return function() {
          return reqStream.destroy();
        };
      }
    });
  };
  createSong = function(app, userId, songId, serviceName, serviceSongId, serviceSongHash, metadata) {
    var data, err, _ref1, _ref2, _ref3, _ref4;
    try {
      data = {
        userId: userId,
        songId: songId,
        serviceName: serviceName,
        serviceSongId: serviceSongId,
        serviceSongHash: serviceSongHash,
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        genre: metadata.genre,
        discNumber: (_ref1 = metadata.disk) != null ? _ref1.no : void 0,
        discNumberTotal: (_ref2 = metadata.disk) != null ? _ref2.of : void 0,
        trackNumber: (_ref3 = metadata.track) != null ? _ref3.no : void 0,
        trackNumberTotal: (_ref4 = metadata.track) != null ? _ref4.of : void 0,
        albumArtistSort: metadata.albumartist
      };
      return Bacon.fromPromise(putSong(app, data));
    } catch (_error) {
      err = _error;
      return new Bacon.Error(err);
    }
  };
  return function(app, userId, serviceName, serviceSongId, serviceSongHash, req, fileSize) {
    var err, songId, stream;
    try {
      songId = getSongId(serviceName, serviceSongId);
      stream = Bacon.fromPromise(getSong(app, userId, songId)).flatMap(function(existingSong) {
        if (existingSong != null) {
          return Bacon.never();
        } else {
          return Bacon.once();
        }
      }).flatMap(function() {
        return getMetadata(req, fileSize);
      }).flatMap(function(metadata) {
        return createSong(app, userId, songId, serviceName, serviceSongId, serviceSongHash, metadata);
      }).mapError(function(err) {
        incrIndexCount(app, userId, serviceName, "numErrors");
        return new Bacon.Error(err);
      }).doAction(function() {
        return incrIndexCount(app, userId, serviceName, "numIndexed");
      });
      return stream;
    } catch (_error) {
      err = _error;
      return new Bacon.Error(err);
    }
  };
})();

removeSong = function(app, indexId, userId, service, serviceSongId, serviceSongHash, req) {
  console.log("Remove Song Request", userId, service, request);
  return Bacon.once("Indexed song");
};

module.exports = function(worker) {
  worker.registerHandler(actionKeys.indexService, function(action) {
    return indexService(worker, action.userId, action.service);
  });
  worker.registerHandler(actionKeys.indexSong, function(action) {
    return indexSong(worker, action.userId, action.service, action.serviceSongId, action.serviceSongHash, action.request, action.fileSize);
  });
  return worker.registerHandler(actionKeys.removeSong, function(action) {
    return removeSong(worker, action.userId, action.service, action.serviceSongId, change.serviceSongHash, action.request);
  });
};
