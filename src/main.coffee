{ Api } = require './api/index'
{ loadConfig } = require './util/config'
api = new Api loadConfig()
api.listen()