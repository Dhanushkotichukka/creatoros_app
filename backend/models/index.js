const sequelize = require('../config/database');
const User = require('./User');
const Token = require('./Token');
const Content = require('./Content');
const Analytics = require('./Analytics');

const syncDatabase = async () => {
    try {
        await sequelize.authenticate();
        console.log('Database connection has been established successfully.');
        
        // Sync models
        await sequelize.sync({ alter: true });
        console.log('Database models synchronized.');
    } catch (error) {
        console.error('Unable to connect to the database:', error);
    }
};

module.exports = {
    sequelize,
    syncDatabase,
    User,
    Token,
    Content,
    Analytics
};
