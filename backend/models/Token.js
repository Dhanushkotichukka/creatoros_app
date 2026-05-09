const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const tokenSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  userId: {
    type: String,
    ref: 'User',
    required: false // Allow null for now, assuming single user or session-based initially if we don't have login, or just require it if we want
  },
  platform: {
    type: String,
    enum: ['youtube', 'meta', 'linkedin'],
    required: true,
  },
  accessToken: {
    type: String,
    required: true,
  },
  refreshToken: {
    type: String,
  },
  refreshToken: { type: String },
  scopes: {
    type: [String],
    default: [],
  },
  expiresAt: {
    type: Date,
  },
  platformAccountId: {
    type: String,
  },
  platformAccountName: {
    type: String,
  },
  profileAvatar: {
    type: String
  },
  extraData: {
    type: Object,
    default: {}
  }
}, {
  timestamps: true,
});

const Token = mongoose.model('Token', tokenSchema);
module.exports = Token;
