_ = require 'lodash'
url = require 'url'
{ getBoolValue, getIntValue } = require './params'
{ modifyReqUrl } = require './url'
{ getHashKey, getRangeKey } = require './model'

queryMeta =
    limit:
        default:50
        max:100
        min:0
    inlineMeta:
        default:false
    totalCount:
        default:false
    start:null

buildGetCollectionEndpoint = (api, parentName, entityName, table, queryFn, idsFn) ->
    hashKey  = getHashKey table
    # Example /users/:userId/songs
    endpoint = "/#{parentName}/:#{hashKey}/#{entityName}"
    api.express.get endpoint, createHandler( api, table, queryFn, idsFn )

createHandler = ( api, table, queryFn, idsFn ) ->
    hashKey  = getHashKey table
    rangeKey = getRangeKey table
    handlerIds = createHandlerIds( api, table, idsFn ) if idsFn?
    handlerQuery = createQueryHandler( api, table, queryFn ) if queryFn?
    (req, res) ->
        handler = if req.query.ids? then handlerIds else handlerQuery
        handler req, res

createHandlerIds = (api, table, idsFn) ->
    return (req, res) ->

createQueryHandler = (api, table, queryFn) ->
    hashKey  = getHashKey table
    rangeKey = getRangeKey table
    return (req, res) ->
        hashId = req.params[ hashKey ]
        rangeId = req.query.start

        #Build query params
        params =
            Limit: getIntValue queryMeta, req, 'limit'
        if req.query.start?
            params.ExclusiveStartKey = {}
            params.ExclusiveStartKey[ hashKey ] = hashId
            params.ExclusiveStartKey[ rangeKey ] = rangeId
        _.extend params, buildSimpleFilters api, req, queryMeta, table

        console.log params
        queryFn api, hashId, params
            .then (results) ->
                inlineMetadata = getBoolValue queryMeta, req, "inlineMeta"
                metadata =
                    next: buildNextPageUrl api, req, results.LastEvaluatedKey?[rangeKey]
                    pageCount: results.Count
                sendResponse res, metadata, results.Items, inlineMetadata

sendResponse = (res, metadata, results, inlineMetadata) ->
    if inlineMetadata
        res.json { metadata, results }
    else
        res.set( "Query-#{key}", val ) for key, val of metadata
        res.json results
    return

buildSimpleFilters = (app, req, queryMeta, tableProperties) ->
    KeyConditions = []
    IndexName = null
    for key, val of req.query
        if typeof queryMeta[key] is "undefined"
            console.log "IndexName", key, typeof queryMeta[key]
            IndexName = "index-#{key}"
            KeyConditions.push app.dbDoc().Condition key, "EQ", val
    return {
        IndexName
        KeyConditions
    }

buildNextPageUrl = (app, req, LastEvaluatedRangeKey) ->
    return null unless LastEvaluatedRangeKey?
    modifyReqUrl app, req, start: LastEvaluatedRangeKey

module.exports = { buildGetCollectionEndpoint }