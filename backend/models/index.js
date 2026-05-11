const connectDB = require('../config/database');
const User = require('./User');
const Token = require('./Token');
const Content = require('./Content');
const Analytics = require('./Analytics');
const Script = require('./Script');
const OTP = require('./OTP');
const CreatorMemory = require('./CreatorMemory');

const syncDatabase = async () => {
    await connectDB();
};

module.exports = {
    syncDatabase,
    User,
    Token,
    Content,
    Analytics,
    Script,
    OTP,
    CreatorMemory,
};
