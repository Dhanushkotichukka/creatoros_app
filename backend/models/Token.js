const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./User');

const Token = sequelize.define('Token', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  platform: {
    type: DataTypes.ENUM('youtube', 'meta', 'linkedin'),
    allowNull: false,
  },
  accessToken: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  refreshToken: {
    type: DataTypes.TEXT,
  },
  scopes: {
    type: DataTypes.JSON,
    defaultValue: [],
  },
  expiresAt: {
    type: DataTypes.DATE,
  },
  platformAccountId: {
    type: DataTypes.STRING,
  },
  platformAccountName: {
    type: DataTypes.STRING,
  }
}, {
  timestamps: true,
});

User.hasMany(Token, { foreignKey: 'userId', as: 'tokens' });
Token.belongsTo(User, { foreignKey: 'userId' });

module.exports = Token;
