#!/usr/bin/env coffee
program = require 'commander'
Promise = require 'bluebird'
_ = require 'underscore'
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
        { Application } = require './app'
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

program.parse process.argv