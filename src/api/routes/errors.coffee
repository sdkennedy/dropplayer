errors = require '../errors'
module.exports = (app) ->

    express = app.express

    # Handle Api Errors
    express.use (err, req, res, next) -> errors.handleApiError err, res, next

    # Handle Sequel Validation Error
    express.use (err, req, res, next) -> errors.handleValidationError err, res, next

    # Handle Generic errors
    #express.use (err, req, res, next) -> errors.handleGenericError err, res, next