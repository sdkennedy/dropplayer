module.exports =
    lambda:
        src:["./lambda/**"]
        dest:"./dropplayer-lambda-<%= meta.revision %>.zip"
    dist:
        cwd:"./dist/"
        src:["./dist/**"]
        dest:"./dropplayer-dist-<%= meta.revision %>.zip"