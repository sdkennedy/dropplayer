var errors, requireParamIsUser;

errors = require('../../errors');

requireParamIsUser = function(userParamKey) {
  return function(req, res, next) {
    if ((req.user != null) && req.user === req.params[userParamKey]) {
      return next();
    } else {
      throw new errors.NotLoggedIn();
    }
  };
};

module.exports = {
  requireParamIsUser: requireParamIsUser
};
