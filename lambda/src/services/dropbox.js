var Bacon, Promise, actionKeys, asyncRequest, filenameIsMusic, getChanges, getServiceOrCreate, getSongUrl, initRoutes, putService, request, serviceName, url, _, _ref;

filenameIsMusic = require('../util/music').filenameIsMusic;

actionKeys = require('../indexer/constants').actionKeys;

Promise = require('bluebird');

request = require('request');

_ = require('underscore');

Bacon = require('baconjs').Bacon;

url = require('url');

_ref = require('../models/services'), getServiceOrCreate = _ref.getServiceOrCreate, putService = _ref.putService;

asyncRequest = Promise.promisify(request);

serviceName = "dropbox";

getChanges = (function() {
  var getChangePage, toChange;
  toChange = function(accessToken, result) {
    var action, metadata, path;
    path = result[0], metadata = result[1];
    action = metadata != null ? actionKeys.indexSong : actionKeys.removeSong;
    return {
      action: action,
      fileSize: metadata.bytes,
      serviceSongId: path,
      serviceSongHash: metadata != null ? metadata.rev : void 0,
      request: {
        url: "https://api-content.dropbox.com/1/files/auto" + (encodeURIComponent(path)),
        headers: {
          Authorization: "Bearer " + accessToken
        }
      }
    };
  };
  getChangePage = function(accessToken, rootDir, cursor, sink) {
    var req;
    req = {
      method: "POST",
      url: "https://api.dropbox.com/1/delta",
      headers: {
        Authorization: "Bearer " + accessToken
      },
      qs: {
        path_prefix: "/Drop Play",
        cursor: cursor
      }
    };
    return asyncRequest(req).spread(function(response, body) {
      var changes, data, err, _ref1;
      try {
        data = JSON.parse(body);
        if ((data != null ? data.entries : void 0) == null) {
          console.log(data);
        }
        changes = ((_ref1 = data != null ? data.entries : void 0) != null ? _ref1 : []).filter(function(result) {
          return filenameIsMusic(result[0]);
        }).map(function(result) {
          return toChange(accessToken, result);
        }).forEach(function(change) {
          return sink(new Bacon.Next({
            change: change
          }));
        });
        if (data.has_more) {
          return getChangePage(accessToken, rootDir, data.cursor, sink);
        } else {
          sink(new Bacon.Next({
            cursor: data.cursor
          }));
          return sink(new Bacon.End());
        }
      } catch (_error) {
        err = _error;
        sink(new Bacon.Error(err));
        return sink(new Bacon.End());
      }
    });
  };
  return function(app, service, full) {
    return Bacon.fromBinder(function(sink) {
      var cursor;
      cursor = full ? null : service.cursor;
      getChangePage(service.accessToken, service.rootDir, cursor, sink);
      return function() {};
    }).flatMap(function(item) {
      if (item.change) {
        return Bacon.once(item.change);
      } else if (item.cursor) {
        service.cursor = item.cursor;
        console.log("Updating dropbox service cursor", service.cursor);
        return Bacon.fromPromise(putService(app, service)).flatMap(function() {
          return Bacon.never();
        });
      } else {
        return Bacon.never();
      }
    });
  };
})();

getSongUrl = function(auth, song) {
  var req;
  req = {
    methos: "POST",
    url: "https://api.dropbox.com/1/media/auto/" + (encodeURIComponent(song.serviceSongId))
  };
  req = authorizeRequest(auth.accessToken, req);
  return asyncRequest(req).spread(function(response, body) {
    return JSON.parse(body);
  });
};

initRoutes = (function() {
  var createService;
  createService = function(accessToken, profile) {
    var _ref1, _ref2;
    return {
      serviceId: "dropbox." + profile.id,
      serviceName: "dropbox",
      displayName: profile.displayName,
      email: (_ref1 = profile.emails) != null ? (_ref2 = _ref1[0]) != null ? _ref2.value : void 0 : void 0,
      accessToken: accessToken,
      rootDir: null,
      cursor: null
    };
  };
  return function(app) {
    var DropboxOAuth2Strategy, dropboxCallback, passport;
    passport = require('passport');
    DropboxOAuth2Strategy = require('passport-dropbox-oauth2').Strategy;
    dropboxCallback = "/auth/dropbox/callback";
    passport.use(new DropboxOAuth2Strategy({
      clientID: app.config.AUTH_DROPBOX_CLIENT_ID,
      clientSecret: app.config.AUTH_DROPBOX_CLIENT_SECRET,
      callbackURL: url.format(_.extend({}, app.config.API_EXTERNAL_HOST, {
        pathname: dropboxCallback
      }))
    }, function(accessToken, refreshToken, profile, done) {
      var service;
      service = createService(accessToken, profile);
      return getServiceOrCreate(app, service).spread(function(user, service) {
        return done(null, user.userId);
      }, function(err) {
        return done(err, null);
      });
    }));
    app.express.get("/auth/dropbox", passport.authenticate('dropbox-oauth2'));
    return app.express.get(dropboxCallback, passport.authenticate('dropbox-oauth2'), function(req, res) {
      return res.json({
        user: url.format(_.extend({}, app.config.API_EXTERNAL_HOST, {
          pathname: "/users/" + req.user
        }))
      });
    });
  };
})();

module.exports = {
  serviceName: serviceName,
  getChanges: getChanges,
  getSongUrl: getSongUrl,
  initRoutes: initRoutes
};
