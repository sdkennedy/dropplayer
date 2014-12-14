var errors, getService, getSongs, getUser, indexService, requireAuthorizedService, requireLogin, requireParamIsUser, _ref, _ref1;

_ref = require('../util/auth'), requireLogin = _ref.requireLogin, requireParamIsUser = _ref.requireParamIsUser, requireAuthorizedService = _ref.requireAuthorizedService;

_ref1 = require('../../indexer/actions'), indexService = _ref1.indexService, getService = _ref1.getService;

getUser = require('../../models/users').getUser;

getSongs = require('../../models/songs').getSongs;

errors = require('../../errors');

module.exports = function(app) {
  var cache, express;
  express = app.express;
  cache = app.cache();
  express.get("/session", requireLogin, function(req, res) {
    return getUser(app, req.user).then(function(user) {
      return res.json(user);
    }, function(err) {
      return res.json(err);
    });
  });
  express.use("/users/:userId", requireParamIsUser("userId"));
  express.get("/users/:userId", function(req, res) {
    return getUser(app, req.params.userId).then(function(user) {
      return res.json(user);
    }, function(err) {
      return res.json(err);
    });
  });
  express.route("/users/:userId/songs").get(function(req, res) {
    return getSongs(app, req.params.userId).then(function(songs) {
      return res.json(songs);
    }, function(err) {
      return res.json(err);
    });
  });
  express.use("/services/:serviceId", requireAuthorizedService(app));
  express.route('/services/:serviceId').get(function(req, res) {
    return res.json(req.service);
  });
  return express.route('/services/:serviceId/actions/index').post(function(req, res) {
    return indexService(app, req.service, true).then(function(service) {
      return res.json(service);
    }, function(err) {
      return res.json(err);
    });
  });
};
