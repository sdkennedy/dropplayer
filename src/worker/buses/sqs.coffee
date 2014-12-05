AWS = require 'aws-sdk'
Promise = require 'bluebird'

createBus = (config) ->
    sqs = new AWS.SQS( config.AWS_AUTH )
    Promise.promisifyAll sqs
    return {
        push:(msg, key) ->
            sqs.sendMessageAsync(
                QueueUrl:app.config.SQS_WORKER_QUEUE
                MessageBody:JSON.stringify(msg)
            )
    }

module.exports = createBus