errors = require '../../errors'

requireParamIsUser = (userParamKey) ->
    return (req, res, next) ->
        if req.user? and req.user is req.params[userParamKey]
            next()
        else
            throw new errors.NotLoggedIn()

module.exports = { requireParamIsUser }