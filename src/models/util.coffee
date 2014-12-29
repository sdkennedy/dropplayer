uuid = require 'node-uuid'
_ = require 'lodash'
{ Bacon } = require 'baconjs'

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

queryAll = (app, queryFn, params) ->
    Bacon.fromPromise queryFn app, params
        .flatMap (result) ->
            streams = [ Bacon.fromArray result.Items ]
            if result.LastEvaluatedKey?
                streams.push queryAll(app, queryFn, { ExclusiveStartKey:result.LastEvaluatedKey })
            Bacon.mergeAll streams

module.exports = { createId, createDate, nullEmptyStrings, createQueryParams, queryAll }