var LambdaWorker, config, loadConfig, worker;

loadConfig = require('./util/config').loadConfig;

LambdaWorker = require('./worker/workers/lambda');

config = loadConfig("" + __dirname + "/config_backend");

worker = new LambdaWorker(config);

module.exports.handler = function(event, context) {
  var _ref;
  console.log("Event", event);
  return (_ref = event.Records) != null ? _ref.forEach(function(record) {
    return worker.processAction(record);
  }) : void 0;
};
