var services, songs, users;

services = require('./services');

songs = require('./songs');

users = require('./users');

module.exports = {
  services: services,
  songs: songs,
  users: users
};
