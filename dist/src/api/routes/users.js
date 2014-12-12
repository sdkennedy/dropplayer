var getIndex, getSongs, getUser, indexService, requireParamIsUser;

requireParamIsUser = require('../util/auth').requireParamIsUser;

indexService = require('../../indexer/actions').indexService;

getIndex = require('../../models/indexes').getIndex;

getUser = require('../../models/users').getUser;

getSongs = require('../../models/songs').getSongs;

module.exports = function(app) {
  var cache, express;
  express = app.express;
  cache = app.cache();
  express.use("/users/:userId", requireParamIsUser("userId"));
  express.get("/users/:userId", function(req, res) {
    return getUser(app, req.params.userId).then(function(user) {
      return res.json(user);
    });
  });
  express.route('/users/:userId/indexes/:service').post(function(req, res) {
    return indexService(app, req.params.userId, req.params.service).then(function(index) {
      return res.json(index);
    });
  }).get(function(req, res) {
    return getIndex(app, req.params.userId, req.params.service).then(function(index) {
      return res.json(index);
    });
  });
  return express.route("/users/:userId/songs").get(function(req, res) {
    return getSongs(app, req.params.userId).then(function(songs) {
      return res.json(songs);
    });
  });
};
