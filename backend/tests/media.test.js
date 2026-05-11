const mediaController = require('../controllers/mediaController');

jest.mock('../services/s3Service', () => ({
    uploadMediaToS3: jest.fn().mockResolvedValue('https://mock-s3-url.com/image.jpg'),
    getUserStorageFiles: jest.fn().mockResolvedValue([
        { url: 'https://mock-s3-url.com/1.jpg', key: '1.jpg', size: 1024, lastModified: new Date() }
    ])
}));

describe('Media Controller', () => {
    let req, res;

    beforeEach(() => {
        req = {
            user: { id: 'test_user_id' },
            query: {},
            file: null
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis()
        };
        jest.clearAllMocks();
    });

    describe('searchMedia', () => {
        it('should return mock search results', async () => {
            req.query = { q: 'test', type: 'image' };
            await mediaController.searchMedia(req, res);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                items: expect.any(Array)
            }));
        });
    });

    describe('uploadFile', () => {
        it('should upload file and return url', async () => {
            req.file = { buffer: Buffer.from('test'), originalname: 'test.jpg', mimetype: 'image/jpeg' };
            await mediaController.uploadFile(req, res);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                url: 'https://mock-s3-url.com/image.jpg'
            }));
        });

        it('should return 400 if no file', async () => {
            await mediaController.uploadFile(req, res);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({ error: 'No file provided' });
        });
    });

    describe('getStorageFiles', () => {
        it('should return list of files', async () => {
            await mediaController.getStorageFiles(req, res);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                files: expect.arrayContaining([
                    expect.objectContaining({ url: 'https://mock-s3-url.com/1.jpg' })
                ])
            }));
        });
    });
});
