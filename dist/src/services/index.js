var dropbox, registerService, requiredKeys, services, verifyRequiredKeys;

dropbox = require('./dropbox');

services = {};

requiredKeys = ['serviceName', 'getSongUrl', 'getChanges', 'initRoutes'];

verifyRequiredKeys = function(service) {
  var key, serviceName, _i, _len, _results;
  serviceName = service.serviceName;
  _results = [];
  for (_i = 0, _len = requiredKeys.length; _i < _len; _i++) {
    key = requiredKeys[_i];
    if (!service[key]) {
      throw new Error("Service " + serviceName + " must has property " + key);
    } else {
      _results.push(void 0);
    }
  }
  return _results;
};

registerService = function(service) {
  var serviceName;
  serviceName = service.serviceName;
  if (services[serviceName] != null) {
    throw new Error("Tried to register service " + serviceName + ", but it is already registered");
  } else {
    verifyRequiredKeys(service);
    return services[serviceName] = service;
  }
};

registerService(dropbox);

module.exports = services;
