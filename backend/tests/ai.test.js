const aiController = require('../controllers/aiController');
const youtubeController = require('../controllers/youtubeController');

jest.mock('../controllers/youtubeController');

// Mock Groq SDK
jest.mock('groq-sdk', () => {
    return {
        Groq: jest.fn().mockImplementation(() => ({
            chat: {
                completions: {
                    create: jest.fn().mockResolvedValue({
                        choices: [{ 
                            message: { 
                                content: JSON.stringify({ 
                                    hook: "Test Hook", 
                                    mainContent: ["point1"], 
                                    callToAction: "Sub",
                                    topics: [{title: "Viral Video", trendScore: 95}],
                                    niche: { primary: "Tech" },
                                    smartTopics: []
                                }) 
                            } 
                        }]
                    })
                }
            }
        }))
    };
});

// Mock Gemini API
jest.mock('@google/generative-ai', () => ({
    GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
        getGenerativeModel: jest.fn()
    }))
}));

// Mock RSS Parser
jest.mock('rss-parser', () => {
    return jest.fn().mockImplementation(() => ({
        parseURL: jest.fn().mockResolvedValue({ items: [
            { title: 'Trending News', link: 'http://news', pubDate: new Date().toISOString() }
        ]})
    }));
});

// Mock Token DB lookup inside aiController
jest.mock('../models/Token', () => ({
    findOne: jest.fn().mockResolvedValue({ platformAccountId: 'test_channel_id' })
}));

describe('AI Controller', () => {
    let req, res;

    beforeEach(() => {
        req = {
            user: { id: 'test_user_id' },
            body: {}
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis()
        };
        jest.clearAllMocks();
    });

    it('getTrendingVideos should return videos array via RSS fallback when YT API fails', async () => {
        req.body.category = 'Tech';
        youtubeController.getYouTubeClient.mockRejectedValue(new Error('Quota exceeded'));
        
        await aiController.getTrendingVideos(req, res);
        
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            videos: expect.arrayContaining([
                expect.objectContaining({ title: 'Trending News', source: 'Google News' })
            ])
        }));
    });

    it('generateScript should return valid script package', async () => {
        req.body = {
            topic: 'How to code',
            platform: 'YouTube',
            styleMode: 'Educational'
        };
        
        await aiController.generateScript(req, res);
        
        expect(res.json).toHaveBeenCalledWith({
            scriptPackage: expect.objectContaining({
                hook: 'Test Hook',
                mainContent: ['point1'],
                callToAction: 'Sub'
            })
        });
    });

    it('getTrendingTopics should return generated topics', async () => {
        req.body.category = 'Vlogs';
        
        await aiController.getTrendingTopics(req, res);
        
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            topics: expect.arrayContaining([
                expect.objectContaining({ title: 'Viral Video' })
            ])
        }));
    });

    it('analyzeChannelInsights should return channel analysis', async () => {
        // Mock YouTube Client to simulate having videos
        youtubeController.getYouTubeClient.mockResolvedValue({
            channels: { list: jest.fn().mockResolvedValue({ data: { items: [{ id: 'ch1', contentDetails: { relatedPlaylists: { uploads: 'pl1' } } }] } }) },
            playlistItems: { list: jest.fn().mockResolvedValue({ data: { items: [{ snippet: { title: 'Vid 1', resourceId: { videoId: 'v1' } } }] } }) }
        });
        
        await aiController.analyzeChannelInsights(req, res);
        
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            analysis: expect.objectContaining({
                niche: expect.objectContaining({ primary: 'Tech' })
            })
        }));
    });
});
