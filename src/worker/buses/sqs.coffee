AWS = require 'aws-sdk'
Promise = require 'bluebird'

createBus = (app) ->
    config = app.config
    sqs = new AWS.SQS(
        credentials:app.awsCredentials()
        region:config.AWS_REGION
    )
    Promise.promisifyAll sqs
    return {
        push:(msg, key) ->
            sqs.sendMessageAsync(
                QueueUrl:config.SQS_WORKER_QUEUE
                MessageBody:JSON.stringify(msg)
            )
    }

module.exports = createBus