const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const contentSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  userId: {
    type: String,
    ref: 'User'
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
    required: true,
  },
  platforms: {
    type: Object,
    default: {},
  },
  status: {
    type: String,
    enum: ['draft', 'scheduled', 'published', 'failed'],
    default: 'draft',
  },
  mediaUrl: {
    type: String,
  },
  thumbnailUrl: {
    type: String,
  },
  scheduledAt: {
    type: Date,
  },
  publishedAt: {
    type: Date,
  },
  aiMetadata: {
    type: Object,
    default: {},
  },
  platformMetadata: {
    type: Object,
    default: {},
  }
}, {
  timestamps: true,
});

const Content = mongoose.model('Content', contentSchema);
module.exports = Content;
