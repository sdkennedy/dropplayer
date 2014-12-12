var Bacon, LambdaWorker, Worker,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Worker = require('./worker');

Bacon = require('baconjs').Bacon;

LambdaWorker = (function(_super) {
  __extends(LambdaWorker, _super);

  function LambdaWorker(config, workerBus) {
    LambdaWorker.__super__.constructor.call(this, config, workerBus);
  }

  LambdaWorker.prototype.processAction = function(record) {
    return LambdaWorker.__super__.processAction.call(this, JSON.parse(new Buffer(record.kinesis.data, 'base64').toString('ascii')));
  };

  return LambdaWorker;

})(Worker);

module.exports = LambdaWorker;
