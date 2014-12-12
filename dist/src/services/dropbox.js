var Bacon, DropboxOAuth2Strategy, Promise, actionKeys, asyncRequest, filenameIsMusic, getChanges, getCredentialsOrCreate, getSongUrl, initRoutes, passport, request, serviceName, url, _;

filenameIsMusic = require('../util/music').filenameIsMusic;

actionKeys = require('../indexer/constants').actionKeys;

Promise = require('bluebird');

request = require('request');

_ = require('underscore');

Bacon = require('baconjs').Bacon;

passport = require('passport');

url = require('url');

DropboxOAuth2Strategy = require('passport-dropbox-oauth2').Strategy;

getCredentialsOrCreate = require('../models/credentials').getCredentialsOrCreate;

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
      var changes, data, err, _ref;
      try {
        data = JSON.parse(body);
        if ((data != null ? data.entries : void 0) == null) {
          console.log(data);
        }
        changes = ((_ref = data != null ? data.entries : void 0) != null ? _ref : []).filter(function(result) {
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
  return function(credentials) {
    return Bacon.fromBinder(function(sink) {
      getChangePage(credentials.accessToken, credentials.rootDir, credentials.cursor, sink);
      return function() {};
    }).flatMap(function(item) {
      if (item.change) {
        return Bacon.once(item.change);
      } else if (item.cursor) {
        return Bacon.fromPromise(auth.save()).flatMap(function() {
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
  var createCredentials;
  createCredentials = function(accessToken, profile) {
    var _ref, _ref1;
    return {
      providerId: "dropbox." + profile.id,
      service: "dropbox",
      displayName: profile.displayName,
      email: (_ref = profile.emails) != null ? (_ref1 = _ref[0]) != null ? _ref1.value : void 0 : void 0,
      accessToken: accessToken,
      rootDir: null,
      cursor: null
    };
  };
  return function(app) {
    var dropboxCallback;
    dropboxCallback = "/auth/dropbox/callback";
    passport.use(new DropboxOAuth2Strategy({
      clientID: app.config.AUTH_DROPBOX_CLIENT_ID,
      clientSecret: app.config.AUTH_DROPBOX_CLIENT_SECRET,
      callbackURL: url.format(_.extend({}, app.config.API_EXTERNAL_HOST, {
        pathname: dropboxCallback
      }))
    }, function(accessToken, refreshToken, profile, done) {
      var credentials;
      credentials = createCredentials(accessToken, profile);
      return getCredentialsOrCreate(app, credentials).then(function(credentials) {
        return done(null, credentials.userId);
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
