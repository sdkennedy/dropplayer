grunt = require 'grunt'
grunt.loadNpmTasks 'grunt-aws-lambda'
grunt.loadNpmTasks 'grunt-contrib-coffee'
grunt.loadNpmTasks 'grunt-contrib-copy'
grunt.loadNpmTasks 'grunt-contrib-clean'

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
            src: ["**/*.json", "src/**/*.js", "node_modules"]
            dest: "dist"
    lambda_invoke:
        default:
            options:
                file_name:"./dist/src/lambda_worker.js"
    lambda_deploy:
        default:
            function: 'dropWorker'
            options:
                region:"us-west-2"
    lambda_package:
        default:
            options:
                package_folder:"./dist"
                dist_folder:"."
)
grunt.registerTask 'build', ['clean', 'coffee', 'copy']
grunt.registerTask 'lambdadeploy', ['build', 'lambda_package', 'lambda_deploy']
grunt.registerTask 'lambdainvoke', ['build', 'lambda_invoke']