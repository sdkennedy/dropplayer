var buses, eager, lambda, sqs, workerTypes;

workerTypes = require('../constants').workerTypes;

eager = require('./eager');

lambda = require('./lambda');

sqs = require('./sqs');

buses = {};

buses[workerTypes.eager] = eager;

buses[workerTypes.lambda] = lambda;

buses[workerTypes.sqs] = sqs;

module.exports = buses;
