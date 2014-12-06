module.exports =
    development:
        DEBUG:true

        # Database configuration loaded from sequelize.json

        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        AWS_AUTH:
            accessKeyId:"AKIAJVEUQHO5IFICBVKQ"
            secretAccessKey:"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"
            region:"us-west-2"

        WORKER_TYPE:"eager"
        SQS_WORKER_QUEUE:"https://sqs.us-west-2.amazonaws.com/711231113371/dropplayer-indexer"
        SQS_WORKER_QUEUE_SIZE:100

        PORT:3000

        API_EXTERNAL_HOST:
            port:3000
            hostname:"localhost"
            protocol:"http:"
            slashes:true
        UI_EXTERNAL_HOST:
            port:3000
            hostname:"localhost"
            protocol:"http:"
            slashes:true

    staging:
        DEBUG:true

        DB_NAME:process.env.RDS_DB_NAME
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

        PORT:process.env.PORT || 3000

        API_EXTERNAL_HOST:
            hostname:"dropplayer.com"
            protocol:"https:"
            slashes:true
        UI_EXTERNAL_HOST:
            hostname:"dropplayer.com"
            protocol:"https:"
            slashes:true