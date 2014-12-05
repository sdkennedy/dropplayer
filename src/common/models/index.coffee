Sequelize = require 'sequelize'
_ = require 'underscore'

getModels = (modelModules) ->
    modelModules.reduce(
        (models, module) ->
            models.push module.model if module?.model?
            return models
        []
    )
getAssociations = (modelModules) ->
    modelModules.reduce(
        (associations, module) ->
            associations.push module.associations if module?.associations?
            return associations
        []
    )

getAllModels = ->
    [
        require './auth_dropbox'
        require './content_indexes'
        require './users'
        require './songs'
    ]

initDb = (dbName, dbUser, dbPassword, dbOptions, modelModules) ->
    sequelize = new Sequelize( dbName, dbUser, dbPassword, dbOptions )
    #Load all modules if none defined
    modelModules ?= getAllModels()
    if modelModules?
        getModels(modelModules).forEach (model) -> model(sequelize)
        getAssociations(modelModules).forEach (association) -> association(sequelize)
    return sequelize

findAssociation = (ChildModel, ParentModel, type=null) ->
    for key, assoc of ParentModel.associations
        continue unless assoc.source is ChildModel
        continue unless type? and assoc.associationType is type
        return assoc
    return null

module.exports = { initDb, findAssociation }