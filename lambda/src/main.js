var Promise, loadConfig, program, tableAlreadyExists, _;

program = require('commander');

Promise = require('bluebird');

_ = require('underscore');

loadConfig = require('./util/config').loadConfig;

program.version('0.0.1').option('-c, --config [config]', 'Path to a backend config file', loadConfig, loadConfig());

program.command('api').description('Starts up api').action(function(env, options) {
  var Api, api;
  Api = require('./api/index').Api;
  api = new Api(program.config);
  return api.listen();
});

tableAlreadyExists = function(tableName) {
  return function(err) {
    var _ref;
    if ((((_ref = err.cause) != null ? _ref.code : void 0) != null) && err.cause.code === "ResourceInUseException") {
      return console.log("" + err.cause.message + " " + tableName);
    } else {
      return Promise.reject(err);
    }
  };
};

program.command('createtables').description('Create dynamodb tables').action(function(env, options) {
  var AWS, Application, app, models, promises;
  AWS = require('aws-sdk');
  Application = require('./app').Application;
  models = require('./models/index');
  app = new Application(program.config);
  promises = _.map(models, function(model, name) {
    console.log("Creating table " + name);
    return typeof model.createTable === "function" ? model.createTable(app)["catch"](tableAlreadyExists(name)) : void 0;
  });
  return Promise.all(promises);
});

program.parse(process.argv);
