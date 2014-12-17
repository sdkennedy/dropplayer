grunt = require 'grunt'
glob = require 'glob'
grunt.loadNpmTasks 'grunt-contrib-coffee'
grunt.loadNpmTasks 'grunt-contrib-copy'
grunt.loadNpmTasks 'grunt-contrib-clean'
grunt.loadNpmTasks 'grunt-zip'
grunt.loadNpmTasks 'grunt-git-revision'
grunt.loadTasks 'grunt_tasks'

loadConfig = (path) ->
    object = {}
    glob.sync('*', {cwd: path}).forEach (option) ->
        key = option.replace(/\.(js|coffee)$/,'')
        object[key] = require(path + option)
    return object

config = {
    pkg: grunt.file.readJSON('package.json')
    env: process.env
}
grunt.util._.extend config, loadConfig('./grunt_tasks/options/')
grunt.initConfig config