var Worker;

Worker = require('./worker/workers/worker');

exports.handler = function(event, context) {
  var _ref;
  console.log("Event2", event);
  return (_ref = event.Records) != null ? _ref.forEach(function(record) {
    var decodedData, err, msg, worker, _ref1;
    try {
      decodedData = new Buffer(record.kinesis.data, 'base64').toString('utf8');
      console.log("decodedData", decodedData);
      msg = JSON.parse(decodedData);
      console.log("msg", msg);
    } catch (_error) {
      err = _error;
      throw new Error("Kinesis record must be JSON");
    }
    if ((msg != null ? (_ref1 = msg.config) != null ? _ref1.AWS_CREDENTIALS_TYPE : void 0 : void 0) != null) {
      delete msg.config.AWS_CREDENTIALS_TYPE;
    }
    worker = new Worker(msg.config);
    return worker.processAction(msg.action);
  }) : void 0;
};
