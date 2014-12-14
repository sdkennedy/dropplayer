var Bacon, EagerWorker, Worker,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Worker = require('./worker');

Bacon = require('baconjs').Bacon;

EagerWorker = (function(_super) {
  __extends(EagerWorker, _super);

  function EagerWorker(config, workerBus) {
    EagerWorker.__super__.constructor.call(this, config, workerBus);
  }

  EagerWorker.prototype.listen = function() {
    var stream;
    stream = this.workerBus().flatMapWithConcurrencyLimit(20, (function(_this) {
      return function(action) {
        return _this.processAction(action);
      };
    })(this));
    stream.onValue(function() {});
    return stream.onError(function(err) {
      return console.log("stream error");
    });
  };

  return EagerWorker;

})(Worker);

module.exports = EagerWorker;
