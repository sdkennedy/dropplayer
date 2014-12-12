var Joi, Promise, createTable, getSong, getSongId, getSongs, nullEmptyStrings, prefixTableName, putSong, songSchema, songsTableName, _ref;

Joi = require('joi');

Promise = require('bluebird');

_ref = require('./util'), nullEmptyStrings = _ref.nullEmptyStrings, prefixTableName = _ref.prefixTableName;

songSchema = Joi.object().keys({
  userId: Joi.string().required(),
  songId: Joi.string().required(),
  serviceName: Joi.string().required(),
  serviceSongId: Joi.string().required(),
  serviceSongHash: Joi.string(),
  title: Joi.string(),
  artist: Joi.array().includes(Joi.string()),
  album: Joi.string(),
  genre: Joi.array().includes(Joi.string()),
  discNumber: Joi.number().integer(),
  discNumberTotal: Joi.number().integer(),
  trackNumber: Joi.number().integer(),
  trackNumberTotal: Joi.number().integer(),
  albumartistsort: Joi.array().includes(Joi.string())
});

songsTableName = "songs";

createTable = function(app) {
  return app.db().createTableAsync({
    TableName: app.config.DYNAMODB_TABLE_SONGS,
    AttributeDefinitions: [
      {
        AttributeName: "userId",
        AttributeType: "S"
      }, {
        AttributeName: "songId",
        AttributeType: "S"
      }
    ],
    KeySchema: [
      {
        AttributeName: "userId",
        KeyType: "HASH"
      }, {
        AttributeName: "songId",
        KeyType: "RANGE"
      }
    ],
    ProvisionedThroughput: {
      ReadCapacityUnits: 3,
      WriteCapacityUnits: 3
    }
  });
};

getSongId = function(serviceName, serviceSongId) {
  return "" + serviceName + "." + serviceSongId;
};

putSong = function(app, song) {
  return app.dbDoc().putItemAsync({
    TableName: app.config.DYNAMODB_TABLE_SONGS,
    Item: nullEmptyStrings(song)
  }).then(function() {
    return song;
  }, function(err) {
    console.log("putSong err", song, err.message);
    return Promise.reject(err);
  });
};

getSong = function(app, userId, songId) {
  return app.dbDoc().getItemAsync({
    TableName: app.config.DYNAMODB_TABLE_SONGS,
    Key: {
      userId: userId,
      songId: songId
    }
  }).then(function(data) {
    return data.Item;
  });
};

getSongs = function(app, userId) {
  var doc;
  doc = app.dbDoc();
  return doc.queryAsync({
    TableName: app.config.DYNAMODB_TABLE_SONGS,
    KeyConditions: [doc.Condition("userId", "EQ", userId)]
  }).then(function(data) {
    return data.Items;
  });
};

module.exports = {
  createTable: createTable,
  getSongId: getSongId,
  putSong: putSong,
  getSong: getSong,
  getSongs: getSongs
};
