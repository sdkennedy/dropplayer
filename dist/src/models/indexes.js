var Joi, Promise, buildIndex, countKeys, createCountCacheKey, createId, createIndex, createInfoCacheKey, errors, getIndex, incrIndexCount, indexSchema, _;

Promise = require('bluebird');

Joi = require('joi');

_ = require('underscore');

createId = require('./util').createId;

errors = require('../errors');

indexSchema = Joi.object().keys({
  indexId: Joi.string().required(),
  userId: Joi.string().required(),
  service: Joi.string().required(),
  numFound: Joi.number().integer(),
  numIndexed: Joi.number().integer(),
  numRemoved: Joi.number().integer(),
  numErrors: Joi.number().integer()
});

countKeys = ['numFound', 'numIndexed', 'numRemoved', 'numErrors'];

createInfoCacheKey = function(userId, service) {
  return "models.indexes.info." + userId + "," + service;
};

createCountCacheKey = function(userId, service, field) {
  return "models.indexes.count." + userId + "," + service + "," + field;
};

buildIndex = function(data) {
  var count, countIndex, counts, index, info;
  info = data[0];
  if (info == null) {
    return null;
  }
  counts = data.slice(1);
  index = _.extend({}, info[1]);
  for (countIndex in counts) {
    count = counts[countIndex];
    index[countKeys[countIndex]] = count[1];
  }
  return index;
};

createIndex = function(app, userId, service) {
  var cache;
  cache = app.cache();
  return getIndex(app, userId, service).then(function(existingIndex) {
    var info, promises;
    if (false && (existingIndex != null) && existingIndex.running) {
      return Promise.reject(new errors.IndexRunningError(service, existingIndex.indexId));
    } else {
      info = {
        indexId: createId(),
        userId: userId,
        service: service,
        running: true
      };
      promises = countKeys.map(function(key) {
        return cache.set(createCountCacheKey(userId, service, key), 0);
      });
      promises = [cache.set(createInfoCacheKey(userId, service), info)].concat(promises);
      return Promise.all(promises).then(buildIndex);
    }
  });
};

getIndex = function(app, userId, service) {
  var cache, promises;
  cache = app.cache();
  promises = countKeys.map(function(key) {
    return cache.get(createCountCacheKey(userId, service, key));
  });
  promises = [cache.get(createInfoCacheKey(userId, service))].concat(promises);
  return Promise.all(promises).then(buildIndex);
};

incrIndexCount = function(app, userId, service, field) {
  return app.cache().incr(createCountCacheKey(userId, service, field));
};

module.exports = {
  createIndex: createIndex,
  getIndex: getIndex,
  incrIndexCount: incrIndexCount
};
