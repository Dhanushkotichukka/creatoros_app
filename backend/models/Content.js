const mongoose = require('mongoose');

const contentSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  title: {
    type: String,
  },
  description: {
    type: String,
  },
  contentType: {
    type: String,
    enum: ['video', 'image', 'post', 'short', 'reel', 'carousel'],
  },
  platforms: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'published', 'failed'],
    default: 'draft',
  },
  mediaUrl: { type: String },
  thumbnailUrl: { type: String },
  scheduledAt: { type: Date },
  publishedAt: { type: Date },
  aiMetadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  platformMetadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Content', contentSchema);
