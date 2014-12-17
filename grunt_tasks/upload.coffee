fs = require 'fs'
AWS = require 'aws-sdk'

module.exports = (grunt) ->
    grunt.task.registerTask 'upload', 'Uploads application distribution to S3', ->
        done = @async()

        zipFilename = grunt.template.process "dropplayer-dist-<%= meta.revision %>.zip"
        grunt.option "distZipFilename", zipFilename

        grunt.log.writeln "Uploading #{zipFilename}"
        s3 = new AWS.S3()
        s3.putObject(
            Bucket:"dropplayer-code"
            Key:zipFilename
            Body:fs.createReadStream zipFilename
            (err, resp) ->
                grunt.log.writeln "Done uploading #{zipFilename}"
                done(if err? then err else true)
        )