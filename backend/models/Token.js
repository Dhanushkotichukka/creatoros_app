const mongoose = require('mongoose');

const tokenSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
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
  refreshToken: { type: String },
  scopes: {
    type: [String],
    default: [],
  },
  expiresAt: { type: Date },
  platformAccountId: { type: String },
  platformAccountName: { type: String },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Token', tokenSchema);
