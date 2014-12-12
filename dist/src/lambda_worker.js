var Worker, loadConfig;

loadConfig = require('./util/config').loadConfig;

Worker = require('./worker/workers/worker');

module.exports.handler = function(event, context) {
  var _ref;
  console.log("Event", event);
  return (_ref = event.Records) != null ? _ref.forEach(function(record) {
    var msg, worker;
    msg = JSON.parse(new Buffer(record.kinesis.data, 'base64').toString('ascii'));
    worker = new Worker(msg.config);
    return worker.processAction(msg.action);
  }) : void 0;
};
