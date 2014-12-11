Joi = require 'joi'
Promise = require 'bluebird'

module.exports.asyncValidate = Promise.promisify Joi.validate