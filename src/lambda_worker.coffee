Worker = require './worker/workers/worker'

exports.handler = (event, context) ->
    console.log "Event", event
    event.Records?.forEach (record) ->
        try
            msg = JSON.parse new Buffer(record.kinesis.data, 'base64').toString('ascii')
        catch err
            throw new Error("Kinesis record must be JSON")
        worker = new Worker msg.config
        worker.processAction msg.action