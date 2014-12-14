{ Bacon } = require 'baconjs'
Promise = require 'bluebird'

createBus = (app) ->
    bus = new Bacon.Bus()
    oldPush = bus.push
    #Push must always return a promise
    bus.push = (msg, key)->
        oldPush.call bus, msg
        Promise.resolve()
    return bus

module.exports = createBus