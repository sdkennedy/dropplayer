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
        console.log "Loading configuration #{path}"
        return require(path)[ process.env.NODE_ENV ? "developement" ]
    catch err
        throw err
        throw new Error "Could not load configuration from: #{path}"