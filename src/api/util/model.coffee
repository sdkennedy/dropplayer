
getKey = (table, type) ->
    keys = table.KeySchema.filter (key) -> key.KeyType is type
    return keys?[0].AttributeName

getHashKey = (table, type) -> getKey table, "HASH"
getRangeKey = (table, type) -> getKey table, "RANGE"

module.exports = { getKey, getHashKey, getRangeKey }