Promise = require 'bluebird'
Joi = require 'joi'
_ = require 'underscore'
{ createId } = require './util'
errors = require '../errors'

indexSchema = Joi.object().keys(

    indexId:Joi.string().required()
    userId:Joi.string().required()
    service:Joi.string().required()

    # Stats
    numFound:Joi.number().integer()
    numIndexed:Joi.number().integer()
    numRemoved:Joi.number().integer()
    numErrors:Joi.number().integer()
)

countKeys = [ 'numFound', 'numIndexed', 'numRemoved', 'numErrors' ]
createInfoCacheKey = (userId, service) -> "models.indexes.info.#{userId},#{service}"
createCountCacheKey = (userId, service, field) -> "models.indexes.count.#{userId},#{service},#{field}"

buildIndex = (data) ->
    info = data[0]
    #Make sure index exists
    return null unless info?

    counts = data[1..]
    index = _.extend {}, info[1]
    for countIndex, count of counts
        index[ countKeys[countIndex] ] = count[1]
    return index

createIndex = (app, userId, service) ->
    cache = app.cache()
    getIndex app, userId, service
        .then (existingIndex) ->
            if false and existingIndex? and existingIndex.running
                #Disable this functionality until elastic cache is set up
                Promise.reject new errors.IndexRunningError( service, existingIndex.indexId )
            else
                info =
                    indexId:createId()
                    userId:userId
                    service:service
                    running:true

                promises = countKeys.map (key) -> cache.set createCountCacheKey(userId, service, key), 0
                promises = [ cache.set( createInfoCacheKey(userId, service), info ) ].concat promises
                Promise.all(promises).then buildIndex

getIndex = (app, userId, service) ->
    cache = app.cache()
    promises = countKeys.map (key) -> cache.get createCountCacheKey(userId, service, key)
    promises = [ cache.get( createInfoCacheKey(userId, service) ) ].concat promises
    Promise.all(promises).then buildIndex

incrIndexCount = (app, userId, service, field) ->
    app.cache().incr createCountCacheKey(userId, service, field)

module.exports = { createIndex, getIndex, incrIndexCount }