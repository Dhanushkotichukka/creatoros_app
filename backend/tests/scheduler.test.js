const dbHandler = require('./dbHandler');
const Content = require('../models/Content');
const schedulerService = require('../services/schedulerService');
const publishController = require('../controllers/publishController');

jest.mock('../controllers/publishController', () => ({
    publishToAll: jest.fn().mockImplementation(async (req, res) => {
        return;
    })
}));

beforeAll(async () => {
    await dbHandler.connect();
});

afterEach(async () => {
    await dbHandler.clearDatabase();
    jest.clearAllMocks();
});

afterAll(async () => {
    await dbHandler.closeDatabase();
});

describe('Scheduler Service Test', () => {
    it('should process scheduled content and update status', async () => {
        const now = new Date();
        const pastDate = new Date(now.getTime() - 1000 * 60); // 1 minute ago

        const scheduledContent = new Content({
            title: 'Test Scheduled Post',
            contentType: 'post',
            status: 'scheduled',
            scheduledAt: pastDate,
        });
        await scheduledContent.save();

        // Run the scheduler job manually instead of waiting for cron
        await schedulerService.processScheduledItems();

        const updatedContent = await Content.findById(scheduledContent._id);
        expect(updatedContent.status).toBe('published');
        expect(publishController.publishToAll).toHaveBeenCalled();
    });

    it('should not process future scheduled content', async () => {
        const now = new Date();
        const futureDate = new Date(now.getTime() + 1000 * 60 * 60); // 1 hour in the future

        const futureContent = new Content({
            title: 'Test Future Post',
            contentType: 'post',
            status: 'scheduled',
            scheduledAt: futureDate,
        });
        await futureContent.save();

        await schedulerService.processScheduledItems();

        const unupdatedContent = await Content.findById(futureContent._id);
        expect(unupdatedContent.status).toBe('scheduled');
    });
});
