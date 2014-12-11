AWS = require 'aws-sdk'
Promise = require 'bluebird'

createBus = (config) ->
    kinesis = new AWS.Kinesis( config.KINESIS_CONFIG )
    Promise.promisifyAll kinesis
    return {
        push:(msg, key) ->
            kinesis.putRecordAsync(
                StreamName:config.KINESIS_WORKER_QUEUE
                PartitionKey:key
                Data:JSON.stringify(msg)
            ).then(
                (result) -> (
                    console.log "result", result
                    return result
                )
                (err) -> (
                    console.log "err", err
                    return err
                )
            )
    }

module.exports = createBus