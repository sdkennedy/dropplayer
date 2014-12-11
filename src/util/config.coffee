fs = require 'fs'
_ = require 'underscore'

module.exports.loadConfig = (config) ->
    return config if typeof config is "object"

    path = switch
        # Load config from config argument
        when typeof config is "string" then config
        # Load config from enviroment variables
        when process.env.DROP_CONFIG? then process.env.DROP_CONFIG
        # Load default config
        else "./config"
    try
        env = process.env.NODE_ENV
        env = "development" unless typeof env is "string" and env.length > 0
        console.log "Environment ", env
        console.log "Loading configuration #{path}"
        #Loadin configuration files
        output = require(path)[env]
        output.ENV = env
        console.log "Loaded configuration ", output
        return output
    catch err
        throw err
        throw new Error "Could not load configuration from: #{path}"