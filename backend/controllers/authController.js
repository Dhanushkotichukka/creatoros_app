const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const { User } = require('../models');

const client = new OAuth2Client();

// POST /auth/google-signin/google
// Receives Google idToken from Flutter, verifies it, finds/creates user, returns JWT
const googleAuth = async (req, res) => {
    try {
        const { idToken } = req.body;
        if (!idToken) {
            return res.status(400).json({ error: 'idToken is required' });
        }

        // Build audience list — must have at least one valid client ID
        const audiences = [
            process.env.GOOGLE_CLIENT_ID,
            process.env.ANDROID_CLIENT_ID,
        ].filter(Boolean);

        if (audiences.length === 0) {
            console.error('[AUTH] FATAL: No Google Client IDs set in environment variables!');
            return res.status(500).json({ error: 'Server auth configuration error.' });
        }

        console.log('[AUTH] Verifying token with audiences:', audiences);

        // Verify the Google ID token
        const ticket = await client.verifyIdToken({ idToken, audience: audiences });
        const payload = ticket.getPayload();
        const { sub: googleId, email, name, picture: profilePicture } = payload;

        // Find or create user — Mongoose syntax
        let user = await User.findOne({ googleId });

        if (!user) {
            // Check by email to avoid duplicates if user signed up differently
            user = await User.findOne({ email });
            if (user) {
                // Link Google ID to existing account
                user.googleId = googleId;
                user.profilePicture = profilePicture;
                await user.save();
            } else {
                // Brand new user
                user = await User.create({ name, email, googleId, profilePicture });
            }
        } else {
            // Refresh profile picture on every login
            user.profilePicture = profilePicture;
            await user.save();
        }

        // Sign JWT with user identity
        const token = jwt.sign(
            { id: user._id, email: user.email, name: user.name },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
        );

        console.log(`[AUTH] User signed in: ${user.email}`);

        return res.json({
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                profilePicture: user.profilePicture,
                phone: user.phone || '',
                bio: user.bio || '',
                creatorScore: user.creatorScore,
            },
        });
    } catch (error) {
        console.error('[AUTH] Google auth error:', error.message);
        console.error('[AUTH] Full error:', error);
        return res.status(401).json({ error: 'Google token verification failed', detail: error.message });
    }
};

// GET /auth/google-signin/me — requires JWT via authMiddleware
const getMe = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('name email profilePicture phone bio creatorScore');
        if (!user) return res.status(404).json({ error: 'User not found' });
        return res.json({ user });
    } catch (error) {
        console.error('[AUTH] getMe error:', error.message);
        return res.status(500).json({ error: 'Failed to fetch user profile' });
    }
};

// PUT /auth/google-signin/profile — update editable profile fields
const updateProfile = async (req, res) => {
    try {
        const { name, phone, bio } = req.body;
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { ...(name && { name }), ...(phone !== undefined && { phone }), ...(bio !== undefined && { bio }) },
            { new: true }
        ).select('name email profilePicture phone bio creatorScore');

        if (!user) return res.status(404).json({ error: 'User not found' });

        console.log(`[AUTH] Profile updated for: ${user.email}`);
        return res.json({ user });
    } catch (error) {
        console.error('[AUTH] updateProfile error:', error.message);
        return res.status(500).json({ error: 'Failed to update profile' });
    }
};

// POST /auth/google-signin/logout — stateless JWT, real logout happens on Flutter side
const logout = (req, res) => {
    return res.json({ success: true, message: 'Logged out successfully' });
};

module.exports = { googleAuth, getMe, updateProfile, logout };
