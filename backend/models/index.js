const connectDatabase = require('../config/database');
const User = require('./User');
const Token = require('./Token');
const Content = require('./Content');
const Analytics = require('./Analytics');
const Script = require('./Script');

module.exports = {
    connectDatabase,
    User,
    Token,
    Content,
    Analytics,
    Script
};
