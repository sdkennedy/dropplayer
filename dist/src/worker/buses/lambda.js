var AWS, Promise, createBus;

AWS = require('aws-sdk');

Promise = require('bluebird');

createBus = function(app) {
  var config, kinesis;
  config = app.config;
  kinesis = new AWS.Kinesis({
    credentials: app.awsCredentials(),
    region: config.AWS_REGION
  });
  Promise.promisifyAll(kinesis);
  return {
    push: function(msg, key) {
      return kinesis.putRecordAsync({
        StreamName: config.KINESIS_WORKER_QUEUE,
        PartitionKey: key,
        Data: JSON.stringify(msg)
      }).then(function(result) {
        console.log("result", result);
        return result;
      }, function(err) {
        console.log("err", err);
        return err;
      });
    }
  };
};

module.exports = createBus;
