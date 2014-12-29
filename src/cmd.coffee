#!/usr/bin/env coffee
program = require 'commander'
Promise = require 'bluebird'
_ = require 'lodash'
{ loadConfig } = require './util/config'

program
    .version '0.0.1'
    .option '-c, --config [config]', 'Path to a backend config file', loadConfig, loadConfig()

program
    .command 'api'
    .description 'Starts up api'
    .action (env, options) ->
        { Api } = require './api/index'
        api = new Api program.config
        api.listen()

program
    .command 'worker'
    .description 'Starts up elastic beanstalk worker'
    .action (env, options) ->
        HttpSQSWorker = require './worker/workers/sqs_http'
        worker = new HttpSQSWorker program.config
        worker.listen()

tableAlreadyExists = (tableName) ->
    (err) ->
        if err.cause?.code? and err.cause.code is "ResourceInUseException"
            console.log "#{err.cause.message} #{tableName}"
        else
            Promise.reject(err)
program
    .command 'createtables'
    .description 'Create dynamodb tables'
    .action (env, options) ->
        AWS = require 'aws-sdk'
        { Application } = require './util/app'
        models = require './models/index'

        app = new Application( program.config )
        promises = _.map(
            models
            (model, name) ->
                console.log "Creating table #{name}"
                if model.createTable
                    model.createTable( app ).catch tableAlreadyExists(name)
                else
                    console.log "No createTable for module #{name}"
        )
        Promise.all(promises)

program
    .command 'purgesongs'
    .description 'Deletes all songs in database'
    .action (env, options) ->
        AWS = require 'aws-sdk'
        { Application } = require './util/app'
        songs = require './models/songs'
        counts = require './models/counts'
        models = { songs, counts }

        app = new Application( program.config )
        _.map(
            models
            (model, modelName) ->
                model.deleteTable app
                    .then(
                        ->
                            console.log "Successfully deleted table #{modelName}"
                            model.createTable app
                                .then(
                                    -> console.log "Successfully recreated table #{modelName}"
                                    (err) -> console.log "Error recreating table #{modelName}", err
                                )
                        (err) -> console.log "Error deleting table #{modelName}", err
                    )
        )

program.parse process.argv