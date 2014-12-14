var Bacon, SQSWorker, Worker,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Worker = require('./worker');

Bacon = require('baconjs').Bacon;

SQSWorker = (function(_super) {
  __extends(SQSWorker, _super);

  function SQSWorker(config, workerBus) {
    SQSWorker.__super__.constructor.call(this, config, workerBus);
    this.queueLength = 0;
    this.retrievingMessages = false;
  }

  SQSWorker.prototype.listen = function() {
    this.checkForMessages();
    return console.log("Listening to requests on url " + this.config.SQS_WORKER_QUEUE);
  };

  SQSWorker.prototype.deleteMessage = function(message) {
    console.log("Removing message " + message.MessageId);
    return this.sqs.deleteMessage({
      QueueUrl: this.config.SQS_WORKER_QUEUE,
      ReceiptHandle: message.ReceiptHandle
    }, function(err, data) {
      if (err != null) {
        console.error("Removing message err", err);
      }
      if (data != null) {
        return console.log("Removing message result", data);
      }
    });
  };

  SQSWorker.prototype.processAction = function(sqsMessage) {
    var action, stream;
    console.log("Processing message " + message.MessageId);
    this.queueLength++;
    action = JSON.parse(sqsMessage.Body);
    stream = SQSWorker.__super__.processAction.call(this, action);
    stream.onEnd((function(_this) {
      return function() {
        console.log("Finished processing message " + message.MessageId);
        _this.queueLength--;
        _this.deleteMessage(message);
        if (_this.readyForMoreMessages()) {
          return _this.checkForMessages();
        }
      };
    })(this));
    return stream;
  };

  SQSWorker.prototype.readyForMoreMessages = function() {
    return !this.retrievingMessages && this.queueLength < this.config.SQS_WORKER_QUEUE_SIZE;
  };

  SQSWorker.prototype.checkForMessages = function() {
    this.retrievingMessages = true;
    return this.sqs.receiveMessage({
      QueueUrl: this.config.SQS_WORKER_QUEUE,
      WaitTimeSeconds: 20,
      VisibilityTimeout: 300
    }, (function(_this) {
      return function(err, data) {
        var messages, _ref;
        _this.retrievingMessages = false;
        messages = (_ref = data.Messages) != null ? _ref : [];
        console.log("Checked for messages, found " + messages.length);
        messages.map(_this.processAction.bind(_this));
        if (_this.readyForMoreMessages()) {
          return _this.checkForMessages();
        }
      };
    })(this));
  };

  return SQSWorker;

})(Worker);

module.exports = SQSWorker;
