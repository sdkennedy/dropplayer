{ getHashKey, getRangeKey } = require './model'

buildGetEntityEndpoint = ( api, table, getFn, endpointNames... ) ->
    hashKey  = getHashKey table
    hasParent = endpointNames.length is 2
    if hasParent
        [ parentName, entityName ] = endpointNames
        rangeKey  = getRangeKey table
        endpoint = "/#{parentName}/:#{hashKey}/#{entityName}/:#{rangeKey}"
    else
        [ entityName ] = endpointNames
        endpoint = "/#{entityName}/:#{hashKey}"
    api.express.get endpoint, createHandler( api, table, getFn, hasParent )

createHandler = ( api, table, getFn, hasParent ) ->
    hashKey  = getHashKey table
    if hasParent
        rangeKey = getRangeKey table
        getIds = (req) -> [ req.params[ hashKey ], req.params[ rangeKey ] ]
    else
        getIds = (req) -> [ req.params[ hashKey ] ]
    (req, res) ->
        ids = getIds req
        getFn api, ids...
            .then(
                (entity) -> res.json entity
                (err) -> res.json err
            )

module.exports = { buildGetEntityEndpoint }