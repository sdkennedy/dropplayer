var Application, Bacon, Promise, Worker, initIndexers,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Application = require('../../app').Application;

initIndexers = require('../../indexer/worker');

Promise = require('bluebird');

Bacon = require('baconjs').Bacon;

Worker = (function(_super) {
  __extends(Worker, _super);

  function Worker(config, workerBus) {
    if (workerBus == null) {
      workerBus = null;
    }
    Worker.__super__.constructor.call(this, config, workerBus);
    this.handlers = {};
    this.registerHandlers();
  }

  Worker.prototype.processAction = function(action) {
    var handler, stream;
    handler = this.handlers[action.type];
    stream = handler(action);
    stream.onError(function(err) {
      console.log("Worker handler error", err);
      if ((err != null ? err.stack : void 0) != null) {
        return console.log("Worker handler error stack", err.stack);
      }
    });
    stream.onValue(function() {});
    return stream;
  };

  Worker.prototype.registerHandlers = function() {
    return initIndexers(this);
  };

  Worker.prototype.registerHandler = function(type, handler) {
    return this.handlers[type] = handler;
  };

  return Worker;

})(Application);

module.exports = Worker;
