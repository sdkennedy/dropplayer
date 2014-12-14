errors = require '../../errors'
{ getService } = require '../../models/services'
requireLogin = (req, res, next) ->
    if req.user?
        next()
    else
        throw new errors.NotLoggedIn()

requireParamIsUser = (userParamKey) ->
    return (req, res, next) ->
        if not req.user?
            throw new errors.NotLoggedIn()
        else if req.user isnt req.params[userParamKey]
            throw new errors.Forbidden()
        else
            next()

requireAuthorizedService = (app) ->
    return (req, res, next) ->
        if not req.user?
            throw new errors.NotLoggedIn()
        else
            getService app, req.params.serviceId
                .then (service) ->
                    if not service?
                        throw new errors.NotFound("service")
                    else if service.userId isnt req.user
                        throw new errors.Forbidden()
                    else
                        req.service = service
                        next()


module.exports = { requireLogin, requireParamIsUser, requireAuthorizedService }