fs = require 'fs'
_ = require 'underscore'

loadSequelize = (env) ->
    filepath = "#{ process.cwd() }/src/sequelize.json"
    keyMap =
        username:"DB_USERNAME"
        database:"DB_NAME"
        password:"DB_PASSWORD"
    return _.reduce(
        #Load Json File
        JSON.parse(
            fs.readFileSync(filepath, 'utf8')
        )[env] ? {}
        #Convert sequelize configuration options to regular config options
        (acc, sVal, sKey) ->
            configKey = keyMap[ sKey ]
            if configKey?
                acc[ configKey ] = sVal
            else
                acc.DB_OPTIONS[ sKey ] = sVal
            return acc
        { DB_OPTIONS:{} }
    )


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
        env = process.env.NODE_ENV
        env = "development" unless typeof env is "string" and env.length > 0
        console.log "Environment ", env
        console.log "Loading configuration #{path}"
        #Loadin configuration files
        output = _.extend(
            ENV:env
            require(path)[env]
            loadSequelize(env)
        )
        console.log "Loaded configuration ", output
        return output
    catch err
        throw err
        throw new Error "Could not load configuration from: #{path}"