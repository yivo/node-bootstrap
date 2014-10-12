require('coffee-script').register();
GLOBAL.rootDirectory = require('path').dirname(process.mainModule.filename);

var TasksManager = require('yivo-node-tasks');
new TasksManager().runTask();