errors = require '../errors'

respondToRejection = (res) ->
    (err) ->
        errors.handleApiError(
            err,
            res,
            (err) ->
                errors.handleValidationError(
                    err,
                    res,
                    (err) -> errors.handleGenericError( err, res )
                )
        )

respondToResolution = (res) ->
    (result) -> res.json result

module.exports = { respondToRejection, respondToResolution }