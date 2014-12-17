module.exports = (grunt) ->
    grunt.registerTask 'build', ['clean:dist', 'coffee:dist', 'copy:dist']