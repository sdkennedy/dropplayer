var Bacon, Promise, actionKeys, actions, getService, getSong, getSongId, getUser, incrIndexCount, indexService, indexSong, musicMetadata, putSong, removeSong, removeSongEntity, request, services, setIndexCount, songs, _, _ref;

getUser = require('../models/users').getUser;

songs = require('../models/songs');

getSongId = songs.getSongId, putSong = songs.putSong, getSong = songs.getSong;

removeSongEntity = songs.removeSong;

_ref = require('../models/services'), getService = _ref.getService, incrIndexCount = _ref.incrIndexCount, setIndexCount = _ref.setIndexCount;

services = require('../services/index');

actions = require('./actions');

actionKeys = require('./constants').actionKeys;

Bacon = require('baconjs').Bacon;

Promise = require('bluebird');

request = require('request');

musicMetadata = require('musicmetadata');

_ = require('underscore');

indexService = (function() {
  var callChangeAction;
  callChangeAction = function(app, serviceId, userId, change) {
    var action, err;
    try {
      if (actions[change.action] != null) {
        action = actions[change.action];
        return Bacon.fromPromise(action(app, userId, serviceId, change.serviceSongId, change.serviceSongHash, change.request, change.fileSize));
      } else {
        return new Bacon.Error("Could no find indexer action for " + change.action);
      }
    } catch (_error) {
      err = _error;
      return new Bacon.Error(err);
    }
  };
  return function(app, serviceId, full) {
    var err;
    try {
      console.log("indexService(" + serviceId + ", " + full + ")");
      return Bacon.fromPromise(getService(app, serviceId)).flatMap(function(service) {
        var changesStream;
        changesStream = services[service.serviceName].getChanges(app, service, full);
        changesStream.scan(0, function(acc, val) {
          return acc + 1;
        }).throttle(250).onValue(function(value) {
          if (value > 0) {
            console.log("setting numFound " + value);
            return setIndexCount(app, serviceId, "numFound", value);
          }
        });
        return changesStream.flatMap(function(change) {
          return callChangeAction(app, serviceId, service.userId, change);
        });
      }).fold(null, function() {}).toEventStream();
    } catch (_error) {
      err = _error;
      return Bacon.Error(err);
    }
  };
})();

indexSong = (function() {
  var createSong, getMetadata, sanitizeMetadata;
  sanitizeMetadata = function(metadata) {
    return _.reduce(metadata, function(newMetadata, val, key) {
      var newVal;
      if (val === "") {
        newVal = null;
      } else if (_.isArray(val)) {
        newVal = val.map(function(subVal) {
          if (subVal === "") {
            return null;
          } else {
            return subVal;
          }
        });
      } else {
        newVal = val;
      }
      newMetadata[key] = newVal;
      return newMetadata;
    }, {});
  };
  getMetadata = function(req, fileSize) {
    return new Bacon.fromBinder(function(sink) {
      var err, parser, reqStream;
      try {
        parser = musicMetadata(reqStream = request(req), {
          fileSize: fileSize
        });
        reqStream.on('error', function(err) {
          console.log('reqest error', err);
          return sink(new Bacon.Error(err));
        });
        parser.on('metadata', function(result) {
          return sink(new Bacon.Next(sanitizeMetadata(result)));
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
  createSong = function(app, userId, serviceId, serviceSongId, serviceSongHash, metadata) {
    var data, err, _ref1, _ref2, _ref3, _ref4;
    try {
      data = {
        userId: userId,
        songId: getSongId(serviceId, serviceSongId),
        serviceId: serviceId,
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
  return function(app, userId, serviceId, serviceSongId, serviceSongHash, req, fileSize) {
    var err, songId, stream;
    console.log("indexSong(" + userId + ", " + serviceId + ", " + serviceSongId + ")");
    try {
      songId = getSongId(serviceId, serviceSongId);
      stream = Bacon.fromPromise(getSong(app, userId, songId)).flatMap(function(existingSong) {
        if (existingSong != null) {
          return Bacon.never();
        } else {
          return Bacon.once();
        }
      }).flatMap(function() {
        return Bacon.retry({
          source: function() {
            return getMetadata(req, fileSize);
          },
          retries: 3,
          delay: 100
        });
      }).flatMap(function(metadata) {
        return createSong(app, userId, serviceId, serviceSongId, serviceSongHash, metadata);
      }).mapError(function(err) {
        incrIndexCount(app, serviceId, "numErrors");
        return new Bacon.Error(err);
      }).doAction(function() {
        return incrIndexCount(app, serviceId, "numIndexed");
      });
      return stream;
    } catch (_error) {
      err = _error;
      return new Bacon.Error(err);
    }
  };
})();

removeSong = function(app, userId, serviceId, serviceSongId, serviceSongHash, req) {
  var songId;
  console.log("removeSong(" + userId + ", " + serviceId + ", " + serviceSongId + ")");
  songId = getSongId(serviceId, serviceSongId);
  return removeSongEntity(app, userId, songId);
};

module.exports = function(worker) {
  worker.registerHandler(actionKeys.indexService, function(action) {
    return indexService(worker, action.serviceId, action.full);
  });
  worker.registerHandler(actionKeys.indexSong, function(action) {
    return indexSong(worker, action.userId, action.serviceId, action.serviceSongId, action.serviceSongHash, action.request, action.fileSize);
  });
  return worker.registerHandler(actionKeys.removeSong, function(action) {
    return removeSong(worker, action.userId, action.serviceId, action.serviceSongId, change.serviceSongHash, action.request);
  });
};
