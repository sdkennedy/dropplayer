Worker = require './worker/workers/worker'

exports.handler = (event, context) ->
    console.log "Event2", event
    event.Records?.forEach (record) ->
        try
            decodedData = new Buffer(record.kinesis.data, 'base64').toString('utf8')
            console.log "decodedData", decodedData
            msg = JSON.parse decodedData
            console.log "msg", msg
        catch err
            throw new Error("Kinesis record must be JSON")
        delete msg.config.AWS_CREDENTIALS_TYPE if msg?.config?.AWS_CREDENTIALS_TYPE?
        worker = new Worker msg.config
        worker.processAction msg.action