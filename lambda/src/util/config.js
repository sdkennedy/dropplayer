var default_config, extname, fs, loadPath, yaml, _;

fs = require('fs');

extname = require('path').extname;

yaml = require('js-yaml');

_ = require('underscore');

default_config = require('../config_backend');

loadPath = function(path, env) {
  switch (extname(path)) {
    case ".yaml":
      return yaml.safeLoad(fs.readFileSync(path));
  }
};

module.exports.loadConfig = function(path) {
  var config, env, err, _ref, _ref1;
  if (path == null) {
    path = process.env.DROP_CONFIG;
  }
  try {
    env = process.env.NODE_ENV;
    if (!(typeof env === "string" && env.length > 0)) {
      env = "development";
    }
    config = {
      ENV: env
    };
    if (default_config[env] != null) {
      _.extend(config, default_config[env]);
    }
    if (path != null) {
      _.extend(config, (_ref = (_ref1 = loadPath(path)) != null ? _ref1[env] : void 0) != null ? _ref : {});
    }
    console.log("Environment ", env);
    console.log("Loading configuration " + path);
    console.log("Loaded configuration ", config);
    return config;
  } catch (_error) {
    err = _error;
    throw err;
    throw new Error("Could not load configuration from: " + path);
  }
};
