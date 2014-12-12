var Bacon, Promise, createBus;

Bacon = require('baconjs').Bacon;

Promise = require('bluebird');

createBus = function(config) {
  var bus;
  bus = new Bacon.Bus();

  /*
  oldPush = bus.push
   *Push must always return a promise
  bus.push = (msg, key)->
      oldPush.call bus, msg
      Promise.resolve()
   */
  return bus;
};

module.exports = createBus;
