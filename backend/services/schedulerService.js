const cron = require('node-cron');
const Content = require('../models/Content');
const publishController = require('../controllers/publishController');
const mongoose = require('mongoose');

// Helper to simulate an Express res object
const mockRes = {
    status: function (s) { this.statusCode = s; return this; },
    json: function (data) { console.log('[SCHEDULER]', data); return this; },
    send: function (data) { console.log('[SCHEDULER]', data); return this; }
};

class SchedulerService {
    start() {
        // Run every minute
        cron.schedule('* * * * *', this.processScheduledItems.bind(this));
        console.log('[SCHEDULER] Cron job started.');
    }

    async processScheduledItems() {
        console.log('[SCHEDULER] Checking for scheduled content...');
        try {
            const now = new Date();
            const scheduledItems = await Content.find({
                status: 'scheduled',
                scheduledAt: { $lte: now }
            });

            if (scheduledItems.length === 0) {
                console.log('[SCHEDULER] No items to publish at this time.');
                return;
            }

            console.log(`[SCHEDULER] Found ${scheduledItems.length} items to publish.`);

            for (const item of scheduledItems) {
                try {
                    console.log(`[SCHEDULER] Publishing item ${item._id}: ${item.title}`);

                    // Create mock req
                    const req = {
                        body: {
                            title: item.title,
                            platformData: JSON.stringify(item.platforms || {}),
                            mediaUrls: item.mediaUrl ? [item.mediaUrl] : []
                        }
                    };

                    // Attempt to publish using the existing controller logic
                    await publishController.publishToAll(req, mockRes);

                    // Update status to published
                    item.status = 'published';
                    item.publishedAt = new Date();
                    await item.save();
                    console.log(`[SCHEDULER] Successfully published and updated item ${item._id}`);
                } catch (publishErr) {
                    console.error(`[SCHEDULER] Failed to publish item ${item._id}:`, publishErr);
                    item.status = 'failed';
                    await item.save();
                }
            }
        } catch (err) {
            console.error('[SCHEDULER] Error processing scheduled content:', err);
        }
    }
}

module.exports = new SchedulerService();
