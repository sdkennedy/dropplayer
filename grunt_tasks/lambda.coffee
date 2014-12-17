fs = require 'fs'
AWS = require 'aws-sdk'
{ loadConfig } = require '../src/util/config'

module.exports = (grunt) ->
    grunt.task.registerTask 'lambdaupload', 'Deploys lambda worker', ->
        done = this.async()
        config = loadConfig()
        functionName = "dropWorker"

        lambda = new AWS.Lambda( region:config.AWS_REGION )
        lambda.getFunction {FunctionName:functionName}, (err, data) ->
            #Build up uploadFunction params
            current = data.Configuration
            params =
                FunctionName: functionName,
                Handler: current.Handler,
                Mode: current.Mode,
                Role: current.Role,
                Runtime: current.Runtime

            console.log "Uploading function"
            fs.readFile "./lambda.zip", (err, data) ->
                params['FunctionZip'] = data
                lambda.uploadFunction params, (err, data) ->
                    console.log(err) if err?
                    grunt.log.writeln('Package deployed.') if not err?
                    done(true)

    grunt.registerTask 'lambdabuild', ['clean:lambda', 'coffee:lambda', 'copy:lambda']
    grunt.registerTask 'lambdadeploy', ['lambdabuild', 'zip', 'lambdaupload']