fs = require 'fs'
AWS = require 'aws-sdk'

module.exports = (grunt) ->
    grunt.registerTask 'deploy', ['clean:dist', 'build', 'revision', 'zip:dist', 'upload', 'cloudformation', 'clean:dist']