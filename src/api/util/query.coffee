_ = require 'underscore'
url = require 'url'

defaultQueryMeta =
    limit:
        default:50
        max:100
        min:0
    inlineMeta:
        default:false
    totalCount:
        default:false
    start:true

getIntValue = (queryMeta, req, key) ->
    metaVal = queryMeta[key] ? {}
    queryVal = req.query[key]
    debugger
    val  = parseInt(queryVal, 10)
    val  = null if isNaN(val)
    val ?= metaVal.default if metaVal.default?
    val  = Math.min(val, metaVal.max) if metaVal.max?
    val  = Math.max(val, metaVal.min) if metaVal.min?
    return val

getBoolValue = (queryMeta, req, key) ->
    metaVal = queryMeta[key] ? {}
    queryVal = req.query[key]
    return queryVal ? metaVal.default ? null

getHashKey = (properties) ->
    keys = properties.KeySchema.filter (key) -> key.KeyType is "HASH"
    return keys?[0].AttributeName

getRangeKey = (properties) ->
    keys = properties.KeySchema.filter (key) -> key.KeyType is "RANGE"
    return keys?[0].AttributeName

buildUrl = (parentName, hashKey, name) ->
    return "/#{parentName}/:#{parentProperties}/#{name}"

queryHandler = (api, getter, parentName, name, properties) ->
    hashKey = getHashKey properties
    rangeKey = getRangeKey properties
    api.express.get(
        buildUrl parentName, hashKey, name
        (req, res) ->
            getter(
                api,
                req.params[hashKey]
                buildQueryParams req, hashKey, rangeKey
            ).then (result) ->

    )

buildSimpleFilters = (app, req, queryMeta, tableProperties) ->
    KeyConditions = []
    IndexName = null
    for key, val of req.query
        if typeof queryMeta[key] is "undefined"
            IndexName = "index-#{key}"
            KeyConditions.push app.dbDoc().Condition key, "EQ", val
    return {
        IndexName
        KeyConditions
    }


buildQueryParams = (app, req, queryMeta, tableProperties) ->
    queryMeta ?= defaultQueryMeta
    hashKey = getHashKey tableProperties
    rangeKey = getRangeKey tableProperties

    params =
        Limit: getIntValue queryMeta, req, 'limit'
    if req.query.start?
        params.ExclusiveStartKey = {}
        params.ExclusiveStartKey[ hashKey ] = req.params[ hashKey ]
        params.ExclusiveStartKey[ rangeKey ] = req.query.start

    _.extend params, buildSimpleFilters(app, req, queryMeta, tableProperties)
    return params

sendQueryResponse = (app, queryMeta, tableProperties, req, res, results) ->
    queryMeta ?= defaultQueryMeta

    hashKey = getHashKey tableProperties
    rangeKey = getRangeKey tableProperties
    inlineMetadata = getBoolValue defaultQueryMeta, req, "inlineMeta"
    respMeta = {
        nextPage:buildNextPageUrl app, req, results.LastEvaluatedKey?[rangeKey]
        pageCount:results.Count
    }
    if inlineMetadata
        res.json(
            metadata:respMeta
            results:results.Items
        )
    else
        res.set("Query-#{metaKey}", metaVal) for metaKey, metaVal of respMeta
        res.json results.Items

buildNextPageUrl = (app, req, LastEvaluatedRangeKey) ->
    return null unless LastEvaluatedRangeKey?
    query = _.extend {}, req.query
    query.start = LastEvaluatedRangeKey
    url.format _.extend(
        {},
        app.config.API_EXTERNAL_HOST,
        pathname:req.path
        query:query
    )


module.exports = { buildQueryParams, sendQueryResponse }