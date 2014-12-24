module.exports =
    dist:
        expand: true
        flatten: false
        cwd: "."
        src: ["node_modules/**","package.json"]
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