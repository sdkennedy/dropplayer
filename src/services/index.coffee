dropbox = require './dropbox'

services = {}
requiredKeys = [ 'serviceName', 'getSongUrl', 'getChanges', 'initRoutes']

verifyRequiredKeys = (service) ->
    { serviceName } = service
    for key in requiredKeys
        if not service[key]
            throw new Error("Service #{serviceName} must has property #{key}")

registerService = (service) ->
    { serviceName } = service
    if services[ serviceName ]?
        throw new Error("Tried to register service #{serviceName}, but it is already registered")
    else
        verifyRequiredKeys service
        services[ serviceName ] = service

registerService(dropbox)

module.exports = services