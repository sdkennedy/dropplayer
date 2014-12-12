var Joi, asyncValidate, createId, createTable, getUser, prefixTableName, putUser, userSchema, usersTableName, _, _ref;

Joi = require('joi');

_ = require('underscore');

asyncValidate = require('../util/joi').asyncValidate;

_ref = require('./util'), createId = _ref.createId, prefixTableName = _ref.prefixTableName;

usersTableName = "users";

createTable = function(app) {
  return app.db().createTableAsync({
    TableName: app.config.DYNAMODB_TABLE_USERS,
    AttributeDefinitions: [
      {
        AttributeName: "userId",
        AttributeType: "S"
      }
    ],
    KeySchema: [
      {
        AttributeName: "userId",
        KeyType: "HASH"
      }
    ],
    ProvisionedThroughput: {
      ReadCapacityUnits: 3,
      WriteCapacityUnits: 3
    }
  });
};

userSchema = Joi.object().keys({
  userId: Joi.string().required(),
  primaryEmail: Joi.string().required(),
  primaryDisplayName: Joi.string().required(),
  dropbox: Joi.object()
});

getUser = function(app, userId) {
  return app.dbDoc().getItemAsync({
    TableName: app.config.DYNAMODB_TABLE_USERS,
    Key: {
      userId: userId
    },
    ConsistentRead: true
  }).then(function(data) {
    console.log("getUser", data);
    return data.Item;
  });
};

putUser = function(app, user) {
  return app.dbDoc().putItemAsync({
    TableName: app.config.DYNAMODB_TABLE_USERS,
    Item: user
  }).then(function() {
    return user;
  });
};

module.exports = {
  createTable: createTable,
  createTable: createTable,
  getUser: getUser,
  putUser: putUser
};
