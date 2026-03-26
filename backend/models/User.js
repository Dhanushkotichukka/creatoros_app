const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  creatorScore: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  preferences: {
    type: DataTypes.JSON,
    defaultValue: {},
  }
}, {
  timestamps: true,
});

module.exports = User;
