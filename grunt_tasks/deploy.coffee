fs = require 'fs'
AWS = require 'aws-sdk'

module.exports = (grunt) ->
    grunt.registerTask 'deploy', ['build', 'revision', 'zip:dist', 'upload', 'cloudformation', 'clean:dist']