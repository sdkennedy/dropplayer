uuid = require 'node-uuid'
_ = require 'underscore'

createId = -> uuid.v4()

nullEmptyStrings = (obj) ->
    _.reduce(
        obj
        (acc, val, key) ->
            acc[key] = if val is "" then null else val
            return acc
        {}
    )

module.exports = { createId, nullEmptyStrings }