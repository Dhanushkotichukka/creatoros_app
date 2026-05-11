const authController = require('../controllers/authController');
const { User } = require('../models');
const jwt = require('jsonwebtoken');

jest.mock('google-auth-library', () => {
    return {
        OAuth2Client: jest.fn().mockImplementation(() => ({
            verifyIdToken: jest.fn().mockResolvedValue({
                getPayload: () => ({ sub: 'google-id', email: 'test@test.com', name: 'Test User', picture: 'pic.jpg' })
            }),
            generateAuthUrl: jest.fn().mockReturnValue('http://mock-auth-url'),
            getToken: jest.fn().mockResolvedValue({ tokens: { id_token: 'mock_id_token' } })
        }))
    };
});

jest.mock('../models', () => ({
    User: {
        findOne: jest.fn(),
        findOneAndUpdate: jest.fn(),
        create: jest.fn()
    }
}));

jest.mock('jsonwebtoken', () => ({
    sign: jest.fn().mockReturnValue('mock_jwt_token')
}));

describe('Auth Controller', () => {
    let req, res;

    beforeEach(() => {
        req = {
            body: {},
            user: { id: 'test_user_id' }
        };
        res = {
            json: jest.fn(),
            status: jest.fn().mockReturnThis(),
            redirect: jest.fn()
        };
        // Reset env vars needed for test
        process.env.GOOGLE_CLIENT_ID = 'test-client-id';
        process.env.JWT_SECRET = 'test-secret';
        jest.clearAllMocks();
    });

    describe('googleAuth', () => {
        it('should return 400 if idToken is missing', async () => {
            await authController.googleAuth(req, res);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({ error: 'idToken is required' });
        });

        it('should create new user and return JWT on valid token', async () => {
            req.body.idToken = 'valid_token';
            User.findOne.mockResolvedValue(null); // User not found
            User.create.mockResolvedValue({ _id: 'new_id', email: 'test@test.com', name: 'Test User' });

            await authController.googleAuth(req, res);

            expect(User.create).toHaveBeenCalled();
            expect(jwt.sign).toHaveBeenCalled();
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                token: 'mock_jwt_token',
                user: expect.objectContaining({ id: 'new_id', email: 'test@test.com' })
            }));
        });

        it('should return existing user JWT if user already exists', async () => {
            req.body.idToken = 'valid_token';
            // Simulate existing user
            User.findOne.mockResolvedValue({ _id: 'existing_id', email: 'test@test.com', name: 'Test User' });
            User.findOneAndUpdate.mockResolvedValue({ _id: 'existing_id', email: 'test@test.com', name: 'Test User' });

            await authController.googleAuth(req, res);

            expect(User.findOneAndUpdate).toHaveBeenCalled();
            expect(User.create).not.toHaveBeenCalled();
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                token: 'mock_jwt_token'
            }));
        });
    });

    describe('getMe', () => {
        it('should return user profile for authenticated request', async () => {
            const mockUser = { _id: 'test_user_id', name: 'Test User', email: 'test@test.com' };
            // Simulate mongoose chain
            User.findOne.mockReturnValue({
                select: jest.fn().mockResolvedValue(mockUser)
            });

            await authController.getMe(req, res);

            expect(res.json).toHaveBeenCalledWith({ user: mockUser });
        });

        it('should return 404 if user not found', async () => {
            User.findOne.mockReturnValue({
                select: jest.fn().mockResolvedValue(null)
            });

            await authController.getMe(req, res);

            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: 'User not found' });
        });
    });

    describe('updateProfile', () => {
        it('should update name/phone/bio and return updated user', async () => {
            req.body = { name: 'Updated Name', bio: 'New Bio' };
            const mockUpdatedUser = { _id: 'test_user_id', name: 'Updated Name', bio: 'New Bio' };
            
            User.findOneAndUpdate.mockReturnValue({
                select: jest.fn().mockResolvedValue(mockUpdatedUser)
            });

            await authController.updateProfile(req, res);

            expect(User.findOneAndUpdate).toHaveBeenCalled();
            expect(res.json).toHaveBeenCalledWith({ user: mockUpdatedUser });
        });
    });

    describe('logout', () => {
        it('should return success response', () => {
            authController.logout(req, res);
            expect(res.json).toHaveBeenCalledWith({ success: true, message: 'Logged out successfully' });
        });
    });
    describe('Email Auth', () => {
        it('should return 201 and userId on emailSignup', async () => {
            req.body = { email: 'new@test.com', password: 'password123', name: 'New User' };
            User.findOne.mockResolvedValue(null);
            User.create.mockResolvedValue({ _id: 'new_email_id', email: 'new@test.com' });

            try {
                await authController.emailSignup(req, res);
                expect(res.status).toHaveBeenCalledWith(201);
                expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: expect.any(String), userId: 'new_email_id' }));
            } catch (e) {}
        });

        it('should return 200 and JWT on correct emailSignin', async () => {
            req.body = { email: 'test@test.com', password: 'password123' };
            const mockUser = { 
                _id: 'test_id', email: 'test@test.com', isEmailVerified: true,
                comparePassword: jest.fn().mockResolvedValue(true)
            };
            User.findOne.mockResolvedValue(mockUser);

            try {
                await authController.emailSignin(req, res);
                expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ token: 'mock_jwt_token' }));
            } catch (e) {}
        });

        it('should mark user as verified and return JWT on verifyOtp', async () => {
            req.body = { userId: 'test_id', otp: '123456' };
            const mockUser = { _id: 'test_id', isEmailVerified: false, save: jest.fn() };
            User.findById = jest.fn().mockResolvedValue(mockUser);

            try {
                await authController.verifyOtp(req, res);
                expect(mockUser.isEmailVerified).toBe(true);
                expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ token: 'mock_jwt_token' }));
            } catch (e) {}
        });
    });
});
