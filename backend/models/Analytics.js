const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Content = require('./Content');

const Analytics = sequelize.define('Analytics', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  platform: {
    type: DataTypes.ENUM('youtube', 'meta', 'linkedin'),
    allowNull: false,
  },
  date: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  views: { type: DataTypes.INTEGER, defaultValue: 0 },
  likes: { type: DataTypes.INTEGER, defaultValue: 0 },
  comments: { type: DataTypes.INTEGER, defaultValue: 0 },
  shares: { type: DataTypes.INTEGER, defaultValue: 0 },
  watchTimeHours: { type: DataTypes.FLOAT, defaultValue: 0 },
  ctr: { type: DataTypes.FLOAT, defaultValue: 0 },
  retentionRate: { type: DataTypes.FLOAT, defaultValue: 0 },
  impressions: { type: DataTypes.INTEGER, defaultValue: 0 },
  platformContentId: { 
    type: DataTypes.STRING, 
  }
}, {
  timestamps: true,
  indexes: [
    {
      unique: false,
      fields: ['contentId', 'platform', 'date']
    }
  ]
});

Content.hasMany(Analytics, { foreignKey: 'contentId', as: 'analytics' });
Analytics.belongsTo(Content, { foreignKey: 'contentId' });

module.exports = Analytics;
