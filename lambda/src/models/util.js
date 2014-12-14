var createDate, createId, nullEmptyStrings, uuid, _;

uuid = require('node-uuid');

_ = require('underscore');

createId = function() {
  return uuid.v4();
};

createDate = function() {
  return (new Date()).toISOString();
};

nullEmptyStrings = function(obj) {
  return _.reduce(obj, function(acc, val, key) {
    acc[key] = val === "" ? null : val;
    return acc;
  }, {});
};

module.exports = {
  createId: createId,
  nullEmptyStrings: nullEmptyStrings,
  createDate: createDate
};
