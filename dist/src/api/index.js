var Api, Application, Bacon, EagerWorker, bodyParser, cookieParser, cookieSession, express, initUserRoutes, passport, services, workerTypes,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Bacon = require('baconjs');

express = require('express');

cookieParser = require('cookie-parser');

bodyParser = require('body-parser');

cookieSession = require('cookie-session');

passport = require('passport');

Application = require('../app').Application;

EagerWorker = require('../worker/workers/eager');

workerTypes = require('../worker/constants').workerTypes;

services = require('../services/index');

initUserRoutes = require('./routes/users');

Api = (function(_super) {
  __extends(Api, _super);

  function Api(config, workerBus) {
    if (workerBus == null) {
      workerBus = null;
    }
    Api.__super__.constructor.call(this, config, workerBus);
    this.express = this.initExpress(this.config);
    this.initPassport();
    this.initRoutes();
    if (this.config.WORKER_TYPE === workerTypes.eager) {
      this.initEagerWorker(this.config);
    }
  }

  Api.prototype.initExpress = function(config) {
    var app;
    app = express();
    app.enable('trust proxy');
    app.use(cookieParser());
    app.use(bodyParser.json());
    app.use(cookieSession({
      name: "session",
      secret: "S3AD0CeRO3C",
      keys: ['PP8lD9a099R1', 'L20F0B008D9PR'],
      signed: true,
      cookie: {
        maxAge: 43200000
      }
    }));
    return app;
  };

  Api.prototype.initPassport = function() {
    this.express.use(passport.initialize());
    this.express.use(passport.session());
    passport.serializeUser(function(id, done) {
      return done(null, id);
    });
    return passport.deserializeUser(function(id, done) {
      return done(null, id);
    });
  };

  Api.prototype.initRoutes = function() {
    var service, serviceName, _results;
    initUserRoutes(this);
    _results = [];
    for (serviceName in services) {
      service = services[serviceName];
      if (this.config.DEBUG) {
        console.log("initializing routing for", serviceName);
      }
      _results.push(service.initRoutes(this));
    }
    return _results;
  };

  Api.prototype.initEagerWorker = function(config) {
    return this.eagerWorker = new EagerWorker(config, this.workerBus());
  };

  Api.prototype.listen = function() {
    var _ref;
    this.express.listen(this.config.PORT);
    if ((_ref = this.eagerWorker) != null) {
      _ref.listen();
    }
    console.log(this.express._router.stack.map(function(route) {
      return [route.name, route.regexp];
    }));
    return console.log("Listening on port " + this.config.PORT);
  };

  return Api;

})(Application);

module.exports = {
  Api: Api
};
