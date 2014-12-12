fs = require 'fs'
{ extname } = require 'path'
yaml = require 'js-yaml'
_ = require 'underscore'
default_config = require '../config_backend'

loadPath = (path, env) ->
    switch extname(path)
        when ".yaml" then yaml.safeLoad( fs.readFileSync(path) )

module.exports.loadConfig = (path) ->
    path ?= process.env.DROP_CONFIG

    try
        env = process.env.NODE_ENV
        env = "development" unless typeof env is "string" and env.length > 0

        config = { ENV:env }
        _.extend( config, default_config[env] ) if default_config[env]?
        _.extend( config, loadPath(path)?[env] ? {} ) if path?

        console.log "Environment ", env
        console.log "Loading configuration #{path}"
        console.log "Loaded configuration ", config
        return config
    catch err
        throw err
        throw new Error "Could not load configuration from: #{path}"