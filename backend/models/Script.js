const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const scriptSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  userId: {
    type: String,
    ref: 'User'
  },
  contentId: {
    type: String,
    ref: 'Content'
  },
  title: {
    type: String,
    required: true,
  },
  topic: {
    type: String,
  },
  content: {
    type: String,
    required: true,
  },
  hook: {
    type: String,
  },
  body: {
    type: String,
  },
  callToAction: {
    type: String,
  },
  durationEstimate: {
    type: Number,
  },
  aiModelUsed: {
    type: String,
  },
  platform: {
    type: String,
  },
  status: {
    type: String,
    enum: ['draft', 'ready', 'used'],
    default: 'draft',
  }
}, {
  timestamps: true,
});

const Script = mongoose.model('Script', scriptSchema);
module.exports = Script;
