uuid = require 'node-uuid'
_ = require 'underscore'

createId = -> uuid.v4()

prefixTableName = (app, tableName) ->
    (app.config.DYNAMODB_TABLE_PREFIX ? '') + tableName

nullEmptyStrings = (obj) ->
    _.reduce(
        obj
        (acc, val, key) ->
            acc[key] = if val is "" then null else val
            return acc
        {}
    )

module.exports = { createId, prefixTableName, nullEmptyStrings }