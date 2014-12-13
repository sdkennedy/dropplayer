AWS = require 'aws-sdk'
{ loadConfig } = require './src/util/config'
fs = require 'fs'
grunt = require 'grunt'

grunt.loadNpmTasks 'grunt-aws-lambda'
grunt.loadNpmTasks 'grunt-contrib-coffee'
grunt.loadNpmTasks 'grunt-contrib-copy'
grunt.loadNpmTasks 'grunt-contrib-clean'
grunt.loadNpmTasks 'grunt-zip'

grunt.initConfig(
    coffee:
        default:
            options:
                bare: true
            expand: true
            flatten: false
            cwd: "."
            src: ["src/**/*.coffee"]
            dest: 'dist'
            ext: ".js"
    clean: [ "./dist"]
    copy:
        default:
            expand: true
            flatten: false
            cwd: "."
            src: ["src/**/*.js", "node_modules/**"]
            dest: "dist"
    lambda_invoke:
        default:
            options:
                file_name:"./dist/src/lambda_worker.js"
    zip:
        "./dist.zip":"./dist/**"

)
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
        fs.readFile "./dist.zip", (err, data) ->
            params['FunctionZip'] = data
            lambda.uploadFunction params, (err, data) ->
                grunt.log.writeln('Package deployed.')
                done(true)


grunt.registerTask 'build', ['clean', 'coffee', 'copy']
grunt.registerTask 'lambdainvoke', ['build', 'lambda_invoke']
grunt.registerTask 'lambdadeploy', ['build', 'zip', 'lambdaupload']