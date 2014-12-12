var AWS, Promise, createBus;

AWS = require('aws-sdk');

Promise = require('bluebird');

createBus = function(app) {
  var config, sqs;
  throw new Error("SQS not configured");
  config = app.config;
  sqs = new AWS.SQS({
    credentials: app.awsCredentials(),
    region: config.AWS_REGION
  });
  Promise.promisifyAll(sqs);
  return {
    push: function(msg, key) {
      return sqs.sendMessageAsync({
        QueueUrl: config.SQS_WORKER_QUEUE,
        MessageBody: JSON.stringify(msg)
      });
    }
  };
};

module.exports = createBus;
