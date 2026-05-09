const dbHandler = require('./dbHandler');
const Token = require('../models/Token');

beforeAll(async () => {
    await dbHandler.connect();
});

afterEach(async () => {
    await dbHandler.clearDatabase();
});

afterAll(async () => {
    await dbHandler.closeDatabase();
});

describe('Token Model Test', () => {
    it('should create and save a token successfully', async () => {
        const tokenData = {
            platform: 'youtube',
            accessToken: 'test_access_token',
            platformAccountId: 'test_id',
        };
        const validToken = new Token(tokenData);
        const savedToken = await validToken.save();

        expect(savedToken._id).toBeDefined();
        expect(savedToken.platform).toBe(tokenData.platform);
        expect(savedToken.accessToken).toBe(tokenData.accessToken);
        expect(savedToken.platformAccountId).toBe(tokenData.platformAccountId);
    });
});
