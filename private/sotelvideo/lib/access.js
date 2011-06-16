/*
(c) 2010 Stephane Alnet
Released under the AGPL3 license
*/
var fs = require('fs');

module.exports = {
  get: function(filename) {
    var data = fs.readFileSync(filename,'utf8').split("\n");
    return {
      username: data[0],
      password: data[1],
    };
  }
};
