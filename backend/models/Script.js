const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Script = sequelize.define('Script', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    topicTitle: {
        type: DataTypes.STRING,
        allowNull: false,
    },
    folder: {
        type: DataTypes.STRING,
        defaultValue: 'general'
    },
    hook: {
        type: DataTypes.TEXT,
    },
    mainContent: {
        type: DataTypes.TEXT,
    },
    callToAction: {
        type: DataTypes.TEXT,
    },
    sourceDetails: {
        type: DataTypes.JSON, // Will store { type: 'YouTube', url: '...', views: '...', date: '...' }
    },
    trendReason: {
        type: DataTypes.TEXT,
    },
    aiRating: {
        type: DataTypes.FLOAT,
    }
}, {
    timestamps: true,
});

module.exports = Script;
