Worker = require './worker'
{ Bacon } = require 'baconjs'

class LambdaWorker extends Worker
    constructor: (config, workerBus) ->
        super config, workerBus

    processAction: (record) ->
        super JSON.parse new Buffer(record.kinesis.data, 'base64').toString('ascii')

module.exports = LambdaWorker