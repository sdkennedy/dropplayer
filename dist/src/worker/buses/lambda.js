var AWS, Promise, createBus;

AWS = require('aws-sdk');

Promise = require('bluebird');

createBus = function(config) {
  var kinesis;
  kinesis = new AWS.Kinesis(config.KINESIS_CONFIG);
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
