module.exports =
    development:
        DEBUG:true

        # Worker Queue
        WORKER_TYPE:"eager"

        # Caching
        CACHE_TYPE:"memory"

        # Dropbox
        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        # AWS Services
        ##############

        AWS_REGION:"us-west-2"
        AWS_CREDENTIALS_TYPE:"shared"

        # Dynamo DB
        DYNAMODB_ENDPOINT:"http://0.0.0.0:8000"
        DYNAMODB_TABLE_SERVICES:"services"
        DYNAMODB_TABLE_USERS:"users"
        DYNAMODB_TABLE_SONGS:"songs"

        # Web Server Configs
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

        # Caching
        CACHE_TYPE:"memory"

        # Dropbox
        AUTH_DROPBOX_CLIENT_ID:"f376r349nw1ixff"
        AUTH_DROPBOX_CLIENT_SECRET:"sxz9uv3igxheygk"

        # AWS Services
        ##############

        AWS_CREDENTIALS_TYPE:"iam"

        # Additional configs loaded in through /home/ec2-user/config_backend.config

        # Kinesis
        KINESIS_WORKER_QUEUE: "drop_worker"

        # Web Server Configs
        PORT:process.env.PORT || 3000

        API_EXTERNAL_HOST:
            hostname:"dropplayer.com"
            protocol:"https:"
            slashes:true
        UI_EXTERNAL_HOST:
            hostname:"dropplayer.com"
            protocol:"https:"
            slashes:true