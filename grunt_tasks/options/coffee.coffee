module.exports =
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