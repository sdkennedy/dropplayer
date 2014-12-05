module.exports =
    developement:
        DEBUG:true

        DB_NAME:"postgres"
        DB_USERNAME:"skennedy"
        DB_PASSWORD:""
        DB_OPTIONS:
            dialect:"postgres"
            port:5432

        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        AWS_AUTH:
            accessKeyId:"AKIAJVEUQHO5IFICBVKQ"
            secretAccessKey:"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"
            region:"us-west-2"

        WORKER_TYPE:"eager"
        SQS_WORKER_QUEUE:"https://sqs.us-west-2.amazonaws.com/711231113371/dropplayer-indexer"
        SQS_WORKER_QUEUE_SIZE:100

        API_HOST:
            port:3000
            hostname:"localhost"
            protocol:"http:"
            slashes:true
        UI_URL:"http://localhost:3000"

    staging:
        DEBUG:true

        DB_NAME:"dropplayer"
        DB_USERNAME:process.env.RDS_USERNAME
        DB_PASSWORD:process.env.RDS_PASSWORD
        DB_OPTIONS:
            dialect:"postgres"
            port:process.env.RDS_PORT
            host:process.env.RDS_HOSTNAME

        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        AWS_AUTH:
            accessKeyId:"AKIAJVEUQHO5IFICBVKQ"
            secretAccessKey:"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"
            region:"us-west-2"

        WORKER_TYPE:"lambda"

        API_HOST:
            port:3000
            hostname:"staging.dropplayer.com"
            protocol:"https:"
            slashes:true
        UI_URL:"https://staging.dropplayer.com"
