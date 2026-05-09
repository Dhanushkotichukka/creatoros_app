const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const analyticsSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  userId: {
    type: String,
    ref: 'User'
  },
  platform: {
    type: String,
    enum: ['youtube', 'meta', 'linkedin'],
    required: true,
  },
  contentId: {
    type: String,
    ref: 'Content'
  },
  date: {
    type: Date,
    required: true,
  },
  metrics: {
    type: Object,
    default: {}
  }
}, {
  timestamps: true,
});

const Analytics = mongoose.model('Analytics', analyticsSchema);
module.exports = Analytics;
