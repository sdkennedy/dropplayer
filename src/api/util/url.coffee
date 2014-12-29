_ = require 'lodash'
url = require 'url'

buildApiUrl = (api, options) ->
    url.format _.extend(
        {},
        api.config.API_EXTERNAL_HOST,
        options
    )

modifyReqUrl = (api, req, query) ->
    options =
        pathname: req.path
        query: _.extend {}, req.query, query
    buildApiUrl api, options

module.exports = { buildApiUrl, modifyReqUrl }