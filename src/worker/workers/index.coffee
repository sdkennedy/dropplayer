{ workerTypes } = require '../constants'
eager = require './eager'
lambda = require './lambda'
sqs = require './sqs'

workers = {}
workers[ workerTypes.eager ] = eager
workers[ workerTypes.lambda ] = lambda
workers[ workerTypes.sqs ] = sqs

module.exports = workers