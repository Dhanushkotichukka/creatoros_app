const publishController = require('../controllers/publishController');
const youtubeController = require('../controllers/youtubeController');
const metaController = require('../controllers/metaController');
const linkedinController = require('../controllers/linkedinController');
const { Content } = require('../models');
const fs = require('fs');
const axios = require('axios');
const { pipeline } = require('stream/promises');

jest.mock('../controllers/youtubeController');
jest.mock('../controllers/metaController');
jest.mock('../controllers/linkedinController');
jest.mock('../models', () => ({
    Content: {
        create: jest.fn()
    }
}));

jest.mock('axios', () => jest.fn().mockResolvedValue({ 
    data: 'mock stream', 
    headers: { 'content-type': 'image/jpeg' } 
}));

jest.mock('fs', () => {
    const actualFs = jest.requireActual('fs');
    return {
        ...actualFs,
        existsSync: jest.fn().mockReturnValue(true),
        mkdirSync: jest.fn(),
        createWriteStream: jest.fn(),
        unlinkSync: jest.fn(),
        writeFileSync: jest.fn(),
    };
});

jest.mock('stream/promises', () => {
    const actualStream = jest.requireActual('stream/promises');
    return {
        ...actualStream,
        pipeline: jest.fn().mockResolvedValue(true)
    };
});

describe('Publish Controller', () => {
    let req, res;

    beforeEach(() => {
        req = {
            user: { id: 'test_user_id' },
            body: {
                title: 'Test Post',
                platformData: '{}',
                mediaUrls: []
            }
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis()
        };
        jest.clearAllMocks();
    });

    it('should return 400 if media URLs are missing when required', async () => {
        // LinkedIn requires media if we don't handle text properly, but here we test the specific logic
        // "Only require media if at least one non-text-only platform is selected"
        // Wait, linkedin supports text only. The controller logic is:
        // const needsMedia = hasYoutube || hasInstagram || (hasLinkedin && urls.length > 0);
        req.body.platformData = JSON.stringify({ youtube: true });
        
        await publishController.publishToAll(req, res);
        
        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith({ error: 'No media URLs provided from S3' });
    });

    it('should publish to LinkedIn with text only (no media)', async () => {
        req.body.platformData = JSON.stringify({ linkedin: { text: 'Hello' } });
        linkedinController.publishToLinkedIn.mockResolvedValue({ success: true, platform: 'LinkedIn', id: 'urn:li:share:123' });
        
        await publishController.publishToAll(req, res);
        
        expect(linkedinController.publishToLinkedIn).toHaveBeenCalled();
        expect(Content.create).toHaveBeenCalled(); // Since it succeeded
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            message: 'Publishing process completed'
        }));
    });

    it('should publish to YouTube and Instagram with media', async () => {
        req.body.platformData = JSON.stringify({ 
            youtube: { title: 'Vid' }, 
            instagram: { caption: 'Pic' } 
        });
        req.body.mediaUrls = ['https://s3.aws.com/vid.mp4']; // simulates video
        
        youtubeController.publishToYouTube.mockResolvedValue({ success: true, platform: 'YouTube', id: 'yt_123' });
        metaController.publishToInstagram.mockResolvedValue({ success: true, platform: 'Instagram', id: 'ig_123' });
        
        await publishController.publishToAll(req, res);
        
        expect(youtubeController.publishToYouTube).toHaveBeenCalled();
        expect(metaController.publishToInstagram).toHaveBeenCalled();
        expect(Content.create).toHaveBeenCalled();
        expect(res.json).toHaveBeenCalled();
    });

    it('should handle API errors gracefully', async () => {
        req.body.platformData = JSON.stringify({ youtube: true });
        req.body.mediaUrls = ['https://s3.aws.com/vid.mp4'];
        
        youtubeController.publishToYouTube.mockRejectedValue(new Error('YT API Error'));
        
        await publishController.publishToAll(req, res);
        
        // It should still complete the process and return the error inside results
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            results: expect.arrayContaining([
                expect.objectContaining({ success: false, platform: 'YouTube', error: 'YT API Error' })
            ])
        }));
    });
});
