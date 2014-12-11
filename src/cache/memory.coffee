Promise = require 'bluebird'
cache = {}

get = (key) -> Promise.resolve([ key, cache[key] ])
set = (key, val) ->
    cache[key] = val
    Promise.resolve([key, val])

incr = (key) ->
    cache[key] += 1
    Promise.resolve([ key, cache[key] ])

module.exports = { get, set, incr }