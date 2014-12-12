module.exports = {
  development: {
    DEBUG: true,
    WORKER_TYPE: "eager",
    CACHE_TYPE: "memory",
    AUTH_DROPBOX_CLIENT_ID: "f376r349nw1ixff",
    AUTH_DROPBOX_CLIENT_SECRET: "sxz9uv3igxheygk",
    AWS_REGION: "us-west-2",
    AWS_CREDENTIALS_TYPE: "shared",
    DYNAMODB_ENDPOINT: "http://0.0.0.0:8000",
    DYNAMODB_TABLE_CREDENTIALS: "credentials",
    DYNAMODB_TABLE_USERS: "users",
    DYNAMODB_TABLE_SONGS: "songs",
    PORT: 3000,
    API_EXTERNAL_HOST: {
      port: 3000,
      hostname: "localhost",
      protocol: "http:",
      slashes: true
    },
    UI_EXTERNAL_HOST: {
      port: 3000,
      hostname: "localhost",
      protocol: "http:",
      slashes: true
    }
  },
  staging: {
    DEBUG: true,
    WORKER_TYPE: "lambda",
    CACHE_TYPE: "memory",
    AUTH_DROPBOX_CLIENT_ID: "f376r349nw1ixff",
    AUTH_DROPBOX_CLIENT_SECRET: "sxz9uv3igxheygk",
    AWS_CREDENTIALS_TYPE: "iam",
    KINESIS_WORKER_QUEUE: "drop_worker",
    PORT: process.env.PORT || 3000,
    API_EXTERNAL_HOST: {
      hostname: "dropplayer.com",
      protocol: "https:",
      slashes: true
    },
    UI_EXTERNAL_HOST: {
      hostname: "dropplayer.com",
      protocol: "https:",
      slashes: true
    }
  }
};
