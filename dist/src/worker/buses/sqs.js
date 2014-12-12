var AWS, Promise, createBus;

AWS = require('aws-sdk');

Promise = require('bluebird');

createBus = function(config) {
  var sqs;
  sqs = new AWS.SQS(config.AWS_CONFIG);
  Promise.promisifyAll(sqs);
  return {
    push: function(msg, key) {
      return sqs.sendMessageAsync({
        QueueUrl: app.config.SQS_WORKER_QUEUE,
        MessageBody: JSON.stringify(msg)
      });
    }
  };
};

module.exports = createBus;
