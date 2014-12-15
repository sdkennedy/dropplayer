AWS = require 'aws-sdk'
{ loadConfig } = require './src/util/config'
fs = require 'fs'
grunt = require 'grunt'

grunt.loadNpmTasks 'grunt-contrib-coffee'
grunt.loadNpmTasks 'grunt-contrib-copy'
grunt.loadNpmTasks 'grunt-contrib-clean'
grunt.loadNpmTasks 'grunt-zip'

grunt.initConfig(
    coffee:
        dist:
            options:
                bare: true
            expand: true
            flatten: false
            cwd: "."
            src: ["src/**/*.coffee"]
            dest: 'dist'
            ext: ".js"
        lambda:
            options:
                bare: true
            expand: true
            flatten: false
            cwd: "."
            src: ["src/**/*.coffee"]
            dest: 'lambda'
            ext: ".js"
    clean:
        dist:["./dist"]
        lambda:["./lambda", "./lambda.zip"]
    copy:
        dist:
            expand: true
            flatten: false
            cwd: "."
            src: ["node_modules/**"]
            dest: "dist"
        lambda:
            expand: true
            flatten: false
            cwd: "."
            src: [
                "node_modules/aws-sdk/**"
                "node_modules/baconjs/**"
                "node_modules/bluebird/**"
                "node_modules/dynamodb-doc/**"
                "node_modules/joi/**"
                "node_modules/js-yaml/**"
                "node_modules/musicmetadata/**"
                "node_modules/node-uuid/**"
                "node_modules/request/**"
                "node_modules/underscore/**"
            ]
            dest: "lambda"

    lambda_invoke:
        default:
            options:
                file_name:"./lambda/src/lambda_worker.js"
    zip:
        lambda:
            src:["./lambda/**"]
            dest:"./lambda.zip"
        dist:
            src:["./dist/**"]
            dest:"./dropplayer-latest.zip"
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
        fs.readFile "./lambda.zip", (err, data) ->
            params['FunctionZip'] = data
            lambda.uploadFunction params, (err, data) ->
                console.log(err) if err?
                grunt.log.writeln('Package deployed.') if not err?
                done(true)


grunt.registerTask 'build', ['clean:dist', 'coffee:dist', 'copy:dist']
grunt.registerTask 'lambdabuild', ['clean:lambda', 'coffee:lambda', 'copy:lambda']
grunt.registerTask 'lambdadeploy', ['lambdabuild', 'zip', 'lambdaupload']