Promise = require 'bluebird'

httpCodes =
    unauthorized:401
    internalServerError:500
    conflict:409
    preconditionFailed:412
    notFound:404

errorIds =
    missingServiceAuth:"missingServiceAuth"
    notLoggedIn:"notLoggedIn"
    internalServerError:"internalServerError"
    validationError:"validationError"
    indexRunning:"indexRunning"
    notFound:""

class ApiError extends Error
    constructor: (@message, @httpCode, @errorCode) ->
        @httpCode ?= httpCodes.internalServerError
        @errorCode ?= errorIds.internalServerError
        super @message

    toJSON: ->
        {
            message:@message
            httpCode:@httpCode
            errorCode:@errorCode
        }

class NotFound extends ApiError
    constructor: (noun) ->
        super "#{noun} does not exist", httpCodes.notFound, errorIds.missingServiceAuth

class UnauthorizedServiceError extends ApiError
    constructor: (service) ->
        super "You have not connected #{service}", httpCodes.unauthorized, errorIds.missingServiceAuth

class NotLoggedIn extends ApiError
    constructor: ->
        super "You must be logged in to complete this action", httpCodes.unauthorized, errorIds.notLoggedIn

class InvalidService extends ApiError
    constructor: (service) ->
        super "Invalid service #{service}", httpCodes.conflict, errorIds.validationError

class IndexRunningError extends ApiError
    constructor: (service, @indexId) ->
        super "Index of #{service} already running", httpCodes.preconditionFailed, errorIds.indexRunning

    toJSON: ->
        obj = super()
        obj.indexId = @indexId
        return obj

module.exports = {
    httpCodes,
    errorIds,
    ApiError,
    UnauthorizedServiceError,
    NotLoggedIn,
    InvalidService,
    IndexRunningError
}