{ authModels } = require '../../common/indexers/sources/index'
errors = require '../errors'

requireParamIsUser = (userParamKey) ->
    return (req, res, next) ->
        userId = parseInt(req.params[userParamKey], 10)
        if req.user? and req.user is userId
            next()
        else
            throw new errors.NotLoggedIn()

requireSourceAuth = (app, sourceParamKey, userParamKey) ->
    return (req, res, next) ->
        userId = parseInt(req.params[userParamKey], 10)
        source = req.params[sourceParamKey]
        Auth = app.db().model authModels[source]
        if Auth?
            Auth
                .find where:{ UserId:userId }
                .then (auth) ->
                    if auth?
                        req.auth = auth
                        next()
                    else
                        throw new errors.UnauthorizedSourceError(source)
        else
            throw new error.InvalidSource(source)

module.exports = { requireParamIsUser, requireSourceAuth }