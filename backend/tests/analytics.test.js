const request = require('supertest');
const express = require('express');
const analyticsRoutes = require('../routes/analyticsRoutes');

jest.mock('../models/Content', () => ({
    find: jest.fn().mockResolvedValue([
        { userId: 'test_user', status: 'published', publishedAt: new Date() }
    ])
}));

jest.mock('../models/Analytics', () => ({
    find: jest.fn().mockResolvedValue([
        { userId: 'test_user', date: new Date(), metrics: { avgViewPercentage: 50 } }
    ])
}));

jest.mock('../models/Token', () => ({
    find: jest.fn().mockResolvedValue([])
}));

const app = express();
app.use(express.json());
// Mock auth middleware
app.use((req, res, next) => {
    req.user = { id: 'test_user' };
    next();
});
app.use('/api/analytics', analyticsRoutes);

describe('Analytics Routes', () => {
    describe('GET /api/analytics/creator-score', () => {
        it('should return creator score metrics', async () => {
            const response = await request(app).get('/api/analytics/creator-score');
            
            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('score');
            expect(response.body).toHaveProperty('metrics');
            expect(Array.isArray(response.body.metrics)).toBe(true);
            expect(response.body.metrics.length).toBe(3);
            expect(response.body.metrics[0].label).toBe('Consistency');
            expect(response.body.metrics[1].label).toBe('Engagement');
            expect(response.body.metrics[2].label).toBe('Frequency');
        });
    });

    describe('GET /api/analytics/overview', () => {
        it('should return analytics overview object', async () => {
            const response = await request(app).get('/api/analytics/overview');
            
            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('totalViews');
            expect(response.body).toHaveProperty('overview');
        });
    });
});
