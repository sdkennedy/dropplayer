getIntValue = (queryMeta, req, key) ->
    metaVal = queryMeta[key] ? {}
    queryVal = req.query[key]
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

module.exports = { getIntValue, getBoolValue }