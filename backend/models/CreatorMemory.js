const mongoose = require('mongoose');

const suggestionSchema = new mongoose.Schema({
    suggestionId: String,
    channelId: String,
    suggestion: mongoose.Schema.Types.Mixed,
    predictedOutcome: String,
    actualRetention: Number,
    actualViews: Number,
    wasHelpful: Boolean,
    recordedAt: { type: Date, default: Date.now },
    resolvedAt: Date
});

const pastInsightSummarySchema = new mongoose.Schema({
    date: Date,
    winningPattern: String,
    topRetention: Number,
    hookScore: Number,
    actionItems: String
});

const creatorMemorySchema = new mongoose.Schema({
    channelId: { type: String, required: true, unique: true },
    niche: String,
    contentStyle: String,
    audienceAge: String,
    bestPostTime: String,
    winningHookType: String,
    avgRetention: Number,
    pastInsightSummaries: [pastInsightSummarySchema],
    pastVideoPerformance: [mongoose.Schema.Types.Mixed],
    improvementAreas: [String],
    suggestions: [suggestionSchema] // feedbackStore migrated here
}, { timestamps: true });

module.exports = mongoose.model('CreatorMemory', creatorMemorySchema);
