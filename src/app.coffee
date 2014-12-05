#!/usr/bin/env coffee
program = require 'commander'
Promise = require 'bluebird'
{ loadConfig } = require './common/util/config'

program
    .version '0.0.1'
    .option '-c, --config [config]', 'Path to a backend config file', loadConfig, loadConfig("#{__dirname}/config_backend.coffee")

# Database related commands
program
    .command 'dbcreate'
    .description 'Creates the database tables for the first time'
    .option '-f --force', 'Force tables to be recreated by dropping them before creating them'
    .action (env, options) ->
        { Application } = require './common/app'
        app = new Application(program.config)
        app.db()
            .sync force:env.force
            .then(
                -> console.log("Successfully created tables")
                (err) -> console.error("Could not create tables", err)
            )

program
    .command 'dbdata'
    .description 'Creates data in the database'
    .action (env, options) ->
        { Application } = require './common/app'
        app = new Application(program.config)
        User = app.db().model 'User'

# Worker related commands
program
    .command 'sqsworker'
    .description 'Starts up SQS worker'
    .action (env, options) ->
        SQSWorker = require('./worker/workers/sqs')
        worker = new SQSWorker(program.config)
        worker.listen()

program
    .command 'api'
    .description 'Starts up api'
    .action (env, options) ->
        { Api } = require './api/index'
        api = new Api(program.config)
        promise = Promise.resolve()
        if api.config.ENV isnt "development"
            promise = promise.then -> api.db().sync()
        promise.then -> api.listen()

program.parse(process.argv)