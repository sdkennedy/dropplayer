{ loadConfig } = require './util/config'
LambdaWorker = require './worker/workers/lambda'

config = loadConfig("#{__dirname}/config_backend")
worker = new LambdaWorker config

module.exports.handler = (event, context) ->
    console.log "Event", event
    event.Records?.forEach (record) -> worker.processAction record