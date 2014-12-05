module.exports.loadConfig = (config) ->
    return config if typeof config is "object"

    path = switch
        # Load config from config argument
        when typeof config is "string" then config
        # Load config from enviroment variables
        when process.env.DROP_CONFIG? then process.env.DROP_CONFIG
        # Load default config
        else "./config.coffee"
    try
        if typeof process.env.NODE_ENV is "string" and process.env.NODE_ENV.length > 0
            env = process.env.NODE_ENV
        else
            env = "developement"
        console.log "Loading configuration #{path} with env #{env}, NODE_ENV #{ process.env.NODE_ENV }"
        config = require(path)[env]
        console.log "Loaded configuration", config
        return config
    catch err
        throw err
        throw new Error "Could not load configuration from: #{path}"