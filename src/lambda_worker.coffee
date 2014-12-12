{ loadConfig } = require './util/config'
Worker = require './worker/workers/worker'

module.exports.handler = (event, context) ->
    console.log "Event", event
    event.Records?.forEach (record) ->
        msg = JSON.parse new Buffer(record.kinesis.data, 'base64').toString('ascii')
        worker = new Worker msg.config
        worker.processAction msg.action