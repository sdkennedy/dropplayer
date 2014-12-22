uuid = require 'node-uuid'
_ = require 'underscore'

createId = -> uuid.v4()
createDate = -> (new Date()).toISOString()

nullEmptyStrings = (obj) ->
    _.reduce(
        obj
        (acc, val, key) ->
            isInvalid = val is "" or not val?
            acc[key] =  val if not isInvalid
            return acc
        {}
    )

createQueryParams = (tableName, hashCondition, additionalParams) ->
    _.extend(
        {},
        additionalParams,
        TableName: tableName
        KeyConditions:[ hashCondition ].concat( additionalParams.KeyConditions ? [] )
    )

module.exports = { createId, createDate, nullEmptyStrings, createQueryParams }