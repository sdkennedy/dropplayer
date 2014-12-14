var Joi, Promise, createDate, createId, createIndex, createTable, errors, getService, getServiceOrCreate, incrIndexCount, putService, putUser, serviceToUser, servicesSchema, setIndexCount, _, _ref;

Joi = require('joi');

Promise = require('bluebird');

_ = require('underscore');

_ref = require('./util'), createId = _ref.createId, createDate = _ref.createDate;

putUser = require('./users').putUser;

errors = require('../errors');

servicesSchema = Joi.object().keys({
  userId: Joi.string().required(),
  serviceId: Joi.string().required(),
  serviceName: Joi.string().required(),
  displayName: Joi.string(),
  email: Joi.string(),
  accessToken: Joi.string(),
  rootDir: Joi.string(),
  cursor: Joi.string()
});

createTable = function(app) {
  return app.db().createTableAsync({
    TableName: app.config.DYNAMODB_TABLE_SERVICES,
    AttributeDefinitions: [
      {
        AttributeName: "serviceId",
        AttributeType: "S"
      }
    ],
    KeySchema: [
      {
        AttributeName: "serviceId",
        KeyType: "HASH"
      }
    ],
    ProvisionedThroughput: {
      ReadCapacityUnits: 3,
      WriteCapacityUnits: 3
    }
  });
};

serviceToUser = function(service) {
  var user;
  user = {
    userId: service.userId,
    primaryEmail: service.email,
    primaryDisplayName: service.displayName,
    createdAt: createDate(),
    services: {}
  };
  user.services[service.serviceName] = service.serviceId;
  return user;
};

getService = function(app, serviceId) {
  return app.dbDoc().getItemAsync({
    TableName: app.config.DYNAMODB_TABLE_SERVICES,
    Key: {
      serviceId: serviceId
    },
    ConsistentRead: true
  }).then(function(data) {
    return data.Item;
  }, function(err) {
    return Promise.reject(new Error("Could not getService " + (JSON.stringify(serviceId)) + ": " + err.message));
  });
};

putService = function(app, service) {
  return app.dbDoc().putItemAsync({
    TableName: app.config.DYNAMODB_TABLE_SERVICES,
    Item: service
  }).then(function() {
    return service;
  }, function() {
    return Promise.reject(new Error("Could not putService " + (service != null ? service.serviceId : void 0)));
  });
};

getServiceOrCreate = function(app, partialService) {
  return getService(app, partialService.serviceId).then(function(service) {
    if (service != null) {
      return service;
    } else {
      service = _.extend({}, partialService, {
        userId: createId()
      });
      return Promise.all([putUser(app, serviceToUser(service)), putService(app, service)]);
    }
  });
};

createIndex = function(app, service) {
  var _ref1;
  if ((service != null ? (_ref1 = service.index) != null ? _ref1.endAt : void 0 : void 0) == null) {
    if (service.index != null) {
      delete service.index;
    }
    service.serviceIndex = {
      startAt: createDate(),
      endAt: null,
      finishedSearch: false,
      finishedIndexing: false,
      numFound: 0,
      numIndexed: 0,
      numRemoved: 0,
      numErrors: 0
    };
    return putService(app, service).then(function() {
      return service;
    }, function(err) {
      return Promise.reject(new Error("Could not create index: " + err.message));
    });
  } else {
    return Promise.reject(new IndexRunningError(service.serviceName));
  }
};

incrIndexCount = function(app, serviceId, key, amount) {
  if (amount == null) {
    amount = 1;
  }
  return app.dbDoc().updateItemAsync({
    TableName: app.config.DYNAMODB_TABLE_SERVICES,
    Key: {
      serviceId: serviceId
    },
    UpdateExpression: "SET serviceIndex." + key + " = serviceIndex." + key + " + :x",
    ExpressionAttributeValues: {
      ":x": amount
    }
  }).then(function() {}, function(err) {
    return Promise.reject(new Error("Could not incrIndexCount(" + serviceId + "," + key + "): " + err.message));
  });
};

setIndexCount = function(app, serviceId, key, count) {
  return app.dbDoc().updateItemAsync({
    TableName: app.config.DYNAMODB_TABLE_SERVICES,
    Key: {
      serviceId: serviceId
    },
    UpdateExpression: "SET serviceIndex." + key + " = :x",
    ExpressionAttributeValues: {
      ":x": count
    }
  }).then(function() {}, function(err) {
    return Promise.reject(new Error("Could not incrIndexCount(" + serviceId + "," + key + "): " + err.message));
  });
};

module.exports = {
  createTable: createTable,
  getService: getService,
  putService: putService,
  getServiceOrCreate: getServiceOrCreate,
  createIndex: createIndex,
  incrIndexCount: incrIndexCount,
  setIndexCount: setIndexCount
};
