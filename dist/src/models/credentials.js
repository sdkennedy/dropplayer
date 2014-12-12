var Joi, Promise, createId, createTable, credentialSchema, credentialsTableName, credentialsToUser, getCredentials, getCredentialsOrCreate, prefixTableName, putCredentials, putUser, _, _ref;

Joi = require('joi');

Promise = require('bluebird');

_ = require('underscore');

_ref = require('./util'), createId = _ref.createId, prefixTableName = _ref.prefixTableName;

putUser = require('./users').putUser;

credentialsTableName = "credentials";

credentialSchema = Joi.object().keys({
  userId: Joi.string().required(),
  providerId: Joi.string().required(),
  service: Joi.string().required(),
  displayName: Joi.string(),
  email: Joi.string(),
  accessToken: Joi.string(),
  rootDir: Joi.string(),
  cursor: Joi.string()
});

createTable = function(app) {
  return app.db().createTableAsync({
    TableName: app.config.DYNAMODB_TABLE_CREDENTIALS,
    AttributeDefinitions: [
      {
        AttributeName: "providerId",
        AttributeType: "S"
      }
    ],
    KeySchema: [
      {
        AttributeName: "providerId",
        KeyType: "HASH"
      }
    ],
    ProvisionedThroughput: {
      ReadCapacityUnits: 3,
      WriteCapacityUnits: 3
    }
  });
};

credentialsToUser = function(credentials) {
  var user;
  user = {
    userId: credentials.userId,
    primaryEmail: credentials.email,
    primaryDisplayName: credentials.displayName,
    createdAt: (new Date()).toISOString(),
    services: {}
  };
  user.services[credentials.service] = credentials.providerId;
  return user;
};

getCredentials = function(app, providerId) {
  return app.dbDoc().getItemAsync({
    TableName: app.config.DYNAMODB_TABLE_CREDENTIALS,
    Key: {
      providerId: providerId
    },
    ConsistentRead: true
  }).then(function(data) {
    console.log("getCredentials", data);
    return data.Item;
  });
};

putCredentials = function(app, credentials) {
  return app.dbDoc().putItemAsync({
    TableName: app.config.DYNAMODB_TABLE_CREDENTIALS,
    Item: credentials
  }).then(function() {
    return credentials;
  });
};

getCredentialsOrCreate = function(app, partialCredentials) {
  return getCredentials(app, partialCredentials.providerId).then(function(credentials) {
    if (credentials != null) {
      return credentials;
    } else {
      credentials = _.extend({}, partialCredentials, {
        userId: createId()
      });
      return Promise.all([putUser(app, credentialsToUser(credentials)), putCredentials(app, credentials)]).spread(function(user, credentials) {
        return credentials;
      });
    }
  });
};

module.exports = {
  credentialsTableName: credentialsTableName,
  createTable: createTable,
  getCredentials: getCredentials,
  putCredentials: putCredentials,
  getCredentialsOrCreate: getCredentialsOrCreate
};
