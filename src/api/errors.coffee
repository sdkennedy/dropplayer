Promise = require 'bluebird'
{ ValidationError } = require 'sequelize'
httpCodes =
    unauthorized:401
    internalServerError:500
    conflict:409
    preconditionFailed:412

errorIds =
    missingSourceAuth:"missingSourceAuth"
    notLoggedIn:"notLoggedIn"
    internalServerError:"internalServerError"
    validationError:"validationError"
    indexRunning:"indexRunning"

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

class UnauthorizedSourceError extends ApiError
    constructor: (source) ->
        super "You have not connected #{source}", httpCodes.unauthorized, errorIds.missingSourceAuth

class NotLoggedIn extends ApiError
    constructor: ->
        super "You must be logged in to complete this action", httpCodes.unauthorized, errorIds.notLoggedIn

class InvalidSource extends ApiError
    constructor: (source) ->
        super "Invalid source #{source}", httpCodes.conflict, errorIds.validationError

class IndexRunningError extends ApiError
    constructor: (source, @contentIndex) ->
        super "Index of #{source} already running", httpCodes.preconditionFailed, errorIds.indexRunning

    toJSON: ->
        obj = super()
        obj.contentIndex = @contentIndex
        return obj

handleApiError = (err, res, next) ->
    if not err?
        next?()
    else if err instanceof ApiError
        res
            .status( err.httpCode )
            .json( err.toJSON() )
    else
        next?(err)

handleValidationError = (err, res, next) ->
    if not err?
        next?()
    else if err instanceof ValidationError
        httpCode = httpCodes.conflict
        errorCode = errorIds.validationError
        res
            .status( httpCode )
            .json({
                message:err.message
                httpCode:httpCode
                errorCode:errorCode
                errors:err.errors
            })
    else
        next?(err)

handleGenericError = (err, res, next) ->
    if not err?
        next?()
    else if err instanceof Error
        httpCode = httpCodes.internalServerError
        errorCode = errorIds.internalServerError
        res
            .status( httpCodes.internalServerError )
            .json({
                message:err.message
                httpCode:httpCode
                errorCode:errorCode
                stack:err.stack
            })
    else
        next?(err)

module.exports = {
    httpCodes,
    errorIds,
    ApiError,
    UnauthorizedSourceError,
    NotLoggedIn,
    InvalidSource,
    IndexRunningError,
    handleApiError,
    handleValidationError,
    handleGenericError,
    handlers:[handleApiError,handleValidationError,handleGenericError]
}