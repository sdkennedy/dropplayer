var AWS, Application, DOC, Promise, caches, workerBuses;

AWS = require('aws-sdk');

DOC = require('dynamodb-doc');

Promise = require('bluebird');

workerBuses = require('./worker/buses/index');

caches = require('./cache/index');

Application = (function() {
  function Application(config, workerBus) {
    if (workerBus == null) {
      workerBus = null;
    }
    this.config = config;
    this._workerBus = workerBus;
  }

  Application.prototype.cache = function() {
    if (this._cache == null) {
      this._cache = caches.memory;
    }
    return this._cache;
  };

  Application.prototype.db = function() {
    if (this._db == null) {
      this.initDb();
    }
    return this._db;
  };

  Application.prototype.dbDoc = function() {
    if (this._dbDoc == null) {
      this.initDbDoc();
    }
    return this._dbDoc;
  };

  Application.prototype.initDb = function() {
    this._db = new AWS.DynamoDB({
      endpoint: this.config.DYNAMODB_ENDPOINT,
      region: this.config.AWS_REGION
    });
    return Promise.promisifyAll(this._db);
  };

  Application.prototype.initDbDoc = function() {
    this._dbDoc = new DOC.DynamoDB(new AWS.DynamoDB({
      endpoint: this.config.DYNAMODB_ENDPOINT,
      region: this.config.AWS_REGION
    }));
    return Promise.promisifyAll(this._dbDoc);
  };

  Application.prototype.workerBus = function() {
    if (this._workerBus == null) {
      this._workerBus = workerBuses[this.config.WORKER_TYPE](this.config);
    }
    return this._workerBus;
  };

  return Application;

})();

module.exports = {
  Application: Application
};
