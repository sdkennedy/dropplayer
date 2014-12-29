Promise = require 'bluebird'
{ getService, setIndexCount } = require '../../models/services'
services = require '../../services/index'
actions = require '../actions'

callChangeAction = (app, serviceId, userId, change) ->
    try
        if actions[change.action]?
            action = actions[change.action]
            return action(
                app,
                userId,
                serviceId,
                change.serviceSongId,
                change.serviceSongHash,
                change.request,
                change.fileSize
            )
        else
            Promise.reject new Error("Could no find indexer action for #{change.action}")
    catch err
        Promise.reject err

indexService = (app, serviceId, full) ->
    try
        console.log "indexService(#{serviceId}, #{full})"
        getService( app, serviceId )
            .then (service) ->
                return new Promise (resolve, reject) ->
                    promises = []
                
                    # Get changes from service
                    changesStream = services[ service.serviceName ]
                        .getChanges app, service, full
                        .endOnError()

                    #Increment count at most once every 250ms
                    changesStream
                        .scan 0, (acc, val) -> acc + 1
                        .throttle 250
                        .onValue (value) ->
                            if value > 0
                                console.log "setting numFound #{value}"
                                setIndexCount app, serviceId, "numFound", value

                    # Create subsequent index / delete action
                    changesStream.onValue (change) ->
                        promises.push callChangeAction app, serviceId, service.userId, change
                    changesStream.onError (err) -> reject err
                    changesStream.onEnd ->
                        Promise.all(promises).then (results) -> resolve results
    catch err
        Promise.reject err

module.exports = indexService