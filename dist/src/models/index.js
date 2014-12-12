var credentials, indexes, songs, users;

credentials = require('./credentials');

indexes = require('./indexes');

songs = require('./songs');

users = require('./users');

module.exports = {
  credentials: credentials,
  indexes: indexes,
  songs: songs,
  users: users
};
