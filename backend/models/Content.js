const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./User');

const Content = sequelize.define('Content', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  title: {
    type: DataTypes.STRING,
  },
  description: {
    type: DataTypes.TEXT,
  },
  contentType: {
    type: DataTypes.ENUM('video', 'image', 'post', 'short', 'reel'),
    allowNull: false,
  },
  platforms: {
    type: DataTypes.JSON,
    defaultValue: [],
  },
  status: {
    type: DataTypes.ENUM('draft', 'scheduled', 'published', 'failed'),
    defaultValue: 'draft',
  },
  mediaUrl: {
    type: DataTypes.STRING,
  },
  thumbnailUrl: {
    type: DataTypes.STRING,
  },
  scheduledAt: {
    type: DataTypes.DATE,
  },
  publishedAt: {
    type: DataTypes.DATE,
  },
  aiMetadata: {
    type: DataTypes.JSON,
    defaultValue: {}, // stores things like AI suggestions, score, scripts used
  },
  platformMetadata: {
    type: DataTypes.JSON,
    defaultValue: {}, // stores platform-specific IDs, engagement stats, etc.
  }
}, {
  timestamps: true,
});

User.hasMany(Content, { foreignKey: 'userId', as: 'contents' });
Content.belongsTo(User, { foreignKey: 'userId' });

module.exports = Content;
