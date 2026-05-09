const connectDB = require('../config/database');
const User = require('./User');
const Token = require('./Token');
const Content = require('./Content');
const Analytics = require('./Analytics');
const Script = require('./Script');

const syncDatabase = async () => {
    // Connect to MongoDB
    await connectDB();
};

module.exports = {
    syncDatabase,
    User,
    Token,
    Content,
    Analytics,
    Script
};
