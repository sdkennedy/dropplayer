var errors, getService, requireAuthorizedService, requireLogin, requireParamIsUser;

errors = require('../../errors');

getService = require('../../models/services').getService;

requireLogin = function(req, res, next) {
  if (req.user != null) {
    return next();
  } else {
    throw new errors.NotLoggedIn();
  }
};

requireParamIsUser = function(userParamKey) {
  return function(req, res, next) {
    if (req.user == null) {
      throw new errors.NotLoggedIn();
    } else if (req.user !== req.params[userParamKey]) {
      throw new errors.Forbidden();
    } else {
      return next();
    }
  };
};

requireAuthorizedService = function(app) {
  return function(req, res, next) {
    if (req.user == null) {
      throw new errors.NotLoggedIn();
    } else {
      return getService(app, req.params.serviceId).then(function(service) {
        if (service == null) {
          throw new errors.NotFound("service");
        } else if (service.userId !== req.user) {
          throw new errors.Forbidden();
        } else {
          req.service = service;
          return next();
        }
      });
    }
  };
};

module.exports = {
  requireLogin: requireLogin,
  requireParamIsUser: requireParamIsUser,
  requireAuthorizedService: requireAuthorizedService
};
