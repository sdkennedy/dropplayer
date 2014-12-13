var Worker;

Worker = require('./worker/workers/worker');

exports.handler = function(event, context) {
  var _ref;
  console.log("Event", event);
  return (_ref = event.Records) != null ? _ref.forEach(function(record) {
    var err, msg, worker;
    try {
      msg = JSON.parse(new Buffer(record.kinesis.data, 'base64').toString('ascii'));
    } catch (_error) {
      err = _error;
      throw new Error("Kinesis record must be JSON");
    }
    worker = new Worker(msg.config);
    return worker.processAction(msg.action);
  }) : void 0;
};
