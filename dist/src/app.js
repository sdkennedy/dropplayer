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
      this._db = new AWS.DynamoDB({
        credentials: this.awsCredentials(),
        endpoint: this.config.DYNAMODB_ENDPOINT,
        region: this.config.AWS_REGION
      });
      Promise.promisifyAll(this._db);
    }
    return this._db;
  };

  Application.prototype.dbDoc = function() {
    if (this._dbDoc == null) {
      this._dbDoc = new DOC.DynamoDB(new AWS.DynamoDB({
        credentials: this.awsCredentials(),
        endpoint: this.config.DYNAMODB_ENDPOINT,
        region: this.config.AWS_REGION
      }));
      Promise.promisifyAll(this._dbDoc);
    }
    return this._dbDoc;
  };

  Application.prototype.awsCredentials = function() {
    if (this._awsCredentials == null) {
      this._awsCredentials = (function() {
        switch (this.config.AWS_CREDENTIALS_TYPE) {
          case "iam":
            return new AWS.EC2MetadataCredentials();
          case "shared":
            return new AWS.SharedIniFileCredentials();
        }
      }).call(this);
    }
    return this._awsCredentials;
  };

  Application.prototype.workerBus = function() {
    if (this._workerBus == null) {
      this._workerBus = workerBuses[this.config.WORKER_TYPE](this);
    }
    return this._workerBus;
  };

  return Application;

})();

module.exports = {
  Application: Application
};
