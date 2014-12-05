Worker = require './worker'
{ Bacon } = require 'baconjs'

class SQSWorker extends Worker
    constructor: (config, workerBus) ->
        super config, workerBus
        @queueLength = 0
        @retrievingMessages = false

    listen: ->
        @checkForMessages()
        console.log "Listening to requests on url #{@config.SQS_WORKER_QUEUE}"

    deleteMessage: (message) ->
        console.log "Removing message #{message.MessageId}"
        @sqs.deleteMessage(
            QueueUrl:@config.SQS_WORKER_QUEUE
            ReceiptHandle:message.ReceiptHandle
            (err, data) ->
                console.error("Removing message err", err) if err?
                console.log("Removing message result", data) if data?
        )

    processAction: (sqsMessage) ->
        console.log "Processing message #{message.MessageId}"
        @queueLength++
        action = JSON.parse(sqsMessage.Body)
        stream = super action
        stream.onEnd =>
            #Now that item is successfully processed, remove it from the queue
            console.log "Finished processing message #{message.MessageId}"
            @queueLength--
            @deleteMessage(message)
            do @checkForMessages if @readyForMoreMessages()
        return stream

    readyForMoreMessages: ->
        not @retrievingMessages and @queueLength < @config.SQS_WORKER_QUEUE_SIZE

    checkForMessages: ->
        @retrievingMessages = true
        @sqs.receiveMessage(
            QueueUrl:@config.SQS_WORKER_QUEUE
            WaitTimeSeconds:20
            VisibilityTimeout:300
            (err, data) =>
                @retrievingMessages = false
                messages = data.Messages ? []

                console.log "Checked for messages, found #{messages.length}"
                messages.map @processAction.bind(@)
                do @checkForMessages if @readyForMoreMessages()
        )

module.exports = SQSWorker