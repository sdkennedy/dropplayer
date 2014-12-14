var ApiError, Forbidden, IndexRunningError, NotFound, NotLoggedIn, Promise, UnauthorizedServiceError, errorIds, httpCodes,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Promise = require('bluebird');

httpCodes = {
  unauthorized: 401,
  forbidden: 403,
  internalServerError: 500,
  conflict: 409,
  preconditionFailed: 412,
  notFound: 404
};

errorIds = {
  missingServiceAuth: "missingServiceAuth",
  notLoggedIn: "notLoggedIn",
  internalServerError: "internalServerError",
  validationError: "validationError",
  indexRunning: "indexRunning",
  notFound: ""
};

ApiError = (function(_super) {
  __extends(ApiError, _super);

  function ApiError(message, httpCode, errorCode) {
    this.message = message;
    this.httpCode = httpCode;
    this.errorCode = errorCode;
    if (this.httpCode == null) {
      this.httpCode = httpCodes.internalServerError;
    }
    if (this.errorCode == null) {
      this.errorCode = errorIds.internalServerError;
    }
    ApiError.__super__.constructor.call(this, this.message);
  }

  ApiError.prototype.toJSON = function() {
    return {
      message: this.message,
      httpCode: this.httpCode,
      errorCode: this.errorCode
    };
  };

  return ApiError;

})(Error);

NotFound = (function(_super) {
  __extends(NotFound, _super);

  function NotFound(noun) {
    NotFound.__super__.constructor.call(this, "" + noun + " does not exist", httpCodes.notFound, errorIds.missingServiceAuth);
  }

  return NotFound;

})(ApiError);

UnauthorizedServiceError = (function(_super) {
  __extends(UnauthorizedServiceError, _super);

  function UnauthorizedServiceError(service) {
    UnauthorizedServiceError.__super__.constructor.call(this, "You have not connected " + service, httpCodes.unauthorized, errorIds.missingServiceAuth);
  }

  return UnauthorizedServiceError;

})(ApiError);

NotLoggedIn = (function(_super) {
  __extends(NotLoggedIn, _super);

  function NotLoggedIn() {
    NotLoggedIn.__super__.constructor.call(this, "You must be logged in to complete this action", httpCodes.unauthorized, errorIds.notLoggedIn);
  }

  return NotLoggedIn;

})(ApiError);

Forbidden = (function(_super) {
  __extends(Forbidden, _super);

  function Forbidden(service) {
    Forbidden.__super__.constructor.call(this, "You do not have the correct credentials to perform this action", httpCodes.forbidden);
  }

  return Forbidden;

})(ApiError);

IndexRunningError = (function(_super) {
  __extends(IndexRunningError, _super);

  function IndexRunningError(service) {
    IndexRunningError.__super__.constructor.call(this, "Index of " + service + " already running", httpCodes.preconditionFailed);
  }

  return IndexRunningError;

})(ApiError);

module.exports = {
  httpCodes: httpCodes,
  errorIds: errorIds,
  ApiError: ApiError,
  UnauthorizedServiceError: UnauthorizedServiceError,
  NotLoggedIn: NotLoggedIn,
  Forbidden: Forbidden,
  IndexRunningError: IndexRunningError
};
