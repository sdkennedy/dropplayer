{ Bacon } = require 'baconjs'
{ getService, setIndexCount } = require '../../models/services'
services = require '../../services/index'
actions = require '../actions'

callChangeAction = (app, serviceId, userId, change) ->
    try
        if actions[change.action]?
            action = actions[change.action]
            Bacon.fromPromise action(
                app,
                userId,
                serviceId,
                change.serviceSongId,
                change.serviceSongHash,
                change.request,
                change.fileSize
            )
        else
            new Bacon.Error("Could no find indexer action for #{change.action}")
    catch err
        new Bacon.Error(err)

indexService = (app, serviceId, full) ->
    try
        console.log "indexService(#{serviceId}, #{full})"
        Bacon
            # Get service from database
            .fromPromise getService( app, serviceId )
            .flatMap (service) ->
                # Get changes from service
                changesStream = services[ service.serviceName ].getChanges app, service, full

                #Increment count at most once every 250ms
                changesStream
                    .scan 0, (acc, val) -> acc + 1
                    .throttle 250
                    .onValue (value) ->
                        if value > 0
                            console.log "setting numFound #{value}"
                            setIndexCount app, serviceId, "numFound", value

                # Create subsequent index / delete action
                return changesStream.take(10).flatMap (change) ->
                    callChangeAction app, serviceId, service.userId, change
            #Bring all changes back together into a single event when complete
            .fold(null, ->)
            .toEventStream()
    catch err
        return Bacon.Error err

module.exports = indexService