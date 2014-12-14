var Promise, cache, get, incr, set;

Promise = require('bluebird');

cache = {};

get = function(key) {
  return Promise.resolve([key, cache[key]]);
};

set = function(key, val) {
  cache[key] = val;
  return Promise.resolve([key, val]);
};

incr = function(key) {
  cache[key] += 1;
  return Promise.resolve([key, cache[key]]);
};

module.exports = {
  get: get,
  set: set,
  incr: incr
};
