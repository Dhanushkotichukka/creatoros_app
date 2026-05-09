const mongoose = require('mongoose');

const analyticsSchema = new mongoose.Schema({
  contentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Content',
  },
  platform: {
    type: String,
    enum: ['youtube', 'meta', 'linkedin'],
    required: true,
  },
  date: { type: Date, required: true },
  views: { type: Number, default: 0 },
  likes: { type: Number, default: 0 },
  comments: { type: Number, default: 0 },
  shares: { type: Number, default: 0 },
  watchTimeHours: { type: Number, default: 0 },
  ctr: { type: Number, default: 0 },
  retentionRate: { type: Number, default: 0 },
  impressions: { type: Number, default: 0 },
  platformContentId: { type: String },
}, {
  timestamps: true,
});

// Index for efficient analytics queries
analyticsSchema.index({ contentId: 1, platform: 1, date: 1 });

module.exports = mongoose.model('Analytics', analyticsSchema);
