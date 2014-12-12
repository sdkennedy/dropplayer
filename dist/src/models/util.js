var createId, nullEmptyStrings, uuid, _;

uuid = require('node-uuid');

_ = require('underscore');

createId = function() {
  return uuid.v4();
};

nullEmptyStrings = function(obj) {
  return _.reduce(obj, function(acc, val, key) {
    acc[key] = val === "" ? null : val;
    return acc;
  }, {});
};

module.exports = {
  createId: createId,
  nullEmptyStrings: nullEmptyStrings
};
