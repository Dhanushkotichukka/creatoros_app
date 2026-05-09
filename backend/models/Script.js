const mongoose = require('mongoose');

const scriptSchema = new mongoose.Schema({
    topicTitle: {
        type: String,
        required: true,
    },
    folder: {
        type: String,
        default: 'general',
    },
    hook: { type: String },
    mainContent: { type: String },
    callToAction: { type: String },
    sourceDetails: {
        type: mongoose.Schema.Types.Mixed, // { type: 'YouTube', url: '...', views: '...', date: '...' }
    },
    trendReason: { type: String },
    aiRating: { type: Number },
}, {
    timestamps: true,
});

module.exports = mongoose.model('Script', scriptSchema);
