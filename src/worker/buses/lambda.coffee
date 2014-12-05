AWS = require 'aws-sdk'
Promise = require 'bluebird'

createBus = ->
    kinesis = new AWS.Kinesis( config.AWS_AUTH )
    Promise.promisifyAll kinesis
    return {
        push:(msg, key) ->
            kinesis.putRecordAsync(
                StreamName:app.config.AWS_KINESIS_WORKER_QUEUE
                PartitionKey:key
                Data:JSON.stringify(msg)
            )
    }

module.exports = createBus