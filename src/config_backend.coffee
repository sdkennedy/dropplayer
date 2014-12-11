module.exports =
    development:
        DEBUG:true

        # Worker Queue
        WORKER_TYPE:"lambda"

        # Dropbox
        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        # Dynamo DB
        DYNAMODB_CONFIG:
            endpoint:"http://0.0.0.0:8000"
            region:"us-west-2"
        DYNAMODB_TABLE_PREFIX:"drop_"

        # Kinesis
        KINESIS_CONFIG:
            region:"us-west-2"
        KINESIS_WORKER_QUEUE: "drop_worker"

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

        # Worker Queue
        WORKER_TYPE:"lambda"

        # Dropbox
        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        # Dynamo DB
        DYNAMODB_CONFIG:
            endpoint:"http://0.0.0.0:8000"
            region:"us-west-2"
        DYNAMODB_TABLE_PREFIX:"drop_"

        # ElasticCache
        # Kinesis
        KINESIS_CONFIG:
            region:"us-west-2"
        KINESIS_WORKER_QUEUE: "drop_worker"
        # Lambda

        PORT:process.env.PORT || 3000

        API_EXTERNAL_HOST:
            hostname:"dropplayer.com"
            protocol:"https:"
            slashes:true
        UI_EXTERNAL_HOST:
            hostname:"dropplayer.com"
            protocol:"https:"
            slashes:true