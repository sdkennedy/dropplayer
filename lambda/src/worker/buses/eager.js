var Bacon, Promise, createBus;

Bacon = require('baconjs').Bacon;

Promise = require('bluebird');

createBus = function(app) {
  var bus, oldPush;
  bus = new Bacon.Bus();
  oldPush = bus.push;
  bus.push = function(msg, key) {
    oldPush.call(bus, msg);
    return Promise.resolve();
  };
  return bus;
};

module.exports = createBus;
