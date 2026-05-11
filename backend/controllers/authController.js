const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { User, OTP } = require('../models');
const { sendVerificationOTP, sendPasswordResetOTP } = require('../services/emailService');

const client = new OAuth2Client(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_WEB_REDIRECT_URI || 'https://creatoros-backend-rb5b.onrender.com/auth/google-signin/web/callback'
);

// ── Helpers ──────────────────────────────────────────────────────────────────

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

const signToken = (user) => jwt.sign(
    { id: user._id, email: user.email, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
);

const userPayload = (user) => ({
    id: user._id,
    name: user.name,
    email: user.email,
    profilePicture: user.profilePicture || '',
    phone: user.phone || '',
    bio: user.bio || '',
    creatorScore: user.creatorScore || 0,
    authProvider: user.authProvider,
    isVerified: user.isVerified,
});

// ── POST /auth/google-signin/signup ──────────────────────────────────────────
const signup = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ error: 'Name, email and password are required.' });
        }
        if (password.length < 8) {
            return res.status(400).json({ error: 'Password must be at least 8 characters.' });
        }

        const existing = await User.findOne({ email: email.toLowerCase().trim() });
        if (existing) {
            if (existing.authProvider === 'google') {
                return res.status(409).json({ error: 'This email is linked to a Google account. Please sign in with Google.' });
            }
            if (existing.isVerified) {
                return res.status(409).json({ error: 'An account with this email already exists.' });
            }
            // Unverified — resend OTP
            const otp = generateOTP();
            await OTP.deleteMany({ userId: existing._id, type: 'verify_email' });
            await OTP.create({
                userId: existing._id,
                email: existing.email,
                otp,
                type: 'verify_email',
                expiresAt: new Date(Date.now() + 10 * 60 * 1000),
            });
            await sendVerificationOTP(existing.email, existing.name, otp);
            return res.status(200).json({ message: 'OTP resent. Please verify your email.', userId: existing._id });
        }

        const hashedPassword = await bcrypt.hash(password, 12);
        const user = await User.create({
            name,
            email: email.toLowerCase().trim(),
            password: hashedPassword,
            authProvider: 'email',
            isVerified: false,
        });

        const otp = generateOTP();
        await OTP.create({
            userId: user._id,
            email: user.email,
            otp,
            type: 'verify_email',
            expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        });

        await sendVerificationOTP(user.email, user.name, otp);

        console.log(`[AUTH] New user signed up: ${user.email}`);
        return res.status(201).json({
            message: 'Account created! Please check your email for the verification code.',
            userId: user._id,
        });
    } catch (error) {
        console.error('[AUTH] signup error:', error.message);
        return res.status(500).json({ error: 'Signup failed. Please try again.' });
    }
};

// ── POST /auth/google-signin/signin ──────────────────────────────────────────
const signin = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required.' });
        }

        const user = await User.findOne({ email: email.toLowerCase().trim() });
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        if (user.authProvider === 'google' && !user.password) {
            return res.status(401).json({ error: 'This account uses Google Sign-In. Please sign in with Google.' });
        }

        if (!user.isVerified) {
            // Resend OTP and prompt verification
            const otp = generateOTP();
            await OTP.deleteMany({ userId: user._id, type: 'verify_email' });
            await OTP.create({
                userId: user._id,
                email: user.email,
                otp,
                type: 'verify_email',
                expiresAt: new Date(Date.now() + 10 * 60 * 1000),
            });
            await sendVerificationOTP(user.email, user.name, otp);
            return res.status(403).json({
                error: 'Email not verified.',
                code: 'EMAIL_NOT_VERIFIED',
                userId: user._id,
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        const token = signToken(user);
        console.log(`[AUTH] User signed in: ${user.email}`);
        return res.json({ token, user: userPayload(user) });
    } catch (error) {
        console.error('[AUTH] signin error:', error.message);
        return res.status(500).json({ error: 'Sign in failed. Please try again.' });
    }
};

// ── POST /auth/google-signin/verify-otp ──────────────────────────────────────
const verifyOtp = async (req, res) => {
    try {
        const { userId, otp, type = 'verify_email' } = req.body;

        if (!userId || !otp) {
            return res.status(400).json({ error: 'userId and otp are required.' });
        }

        const otpRecord = await OTP.findOne({ userId, type, otp });
        if (!otpRecord) {
            return res.status(400).json({ error: 'Invalid or expired OTP.' });
        }
        if (otpRecord.expiresAt < new Date()) {
            await OTP.deleteOne({ _id: otpRecord._id });
            return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
        }

        await OTP.deleteOne({ _id: otpRecord._id });

        if (type === 'verify_email') {
            const user = await User.findOneAndUpdate(
                { _id: userId },
                { $set: { isVerified: true } },
                { new: true }
            );
            if (!user) return res.status(404).json({ error: 'User not found.' });

            const token = signToken(user);
            console.log(`[AUTH] Email verified for: ${user.email}`);
            return res.json({ token, user: userPayload(user) });
        }

        // For reset_password — just confirm OTP is valid, return a short-lived reset token
        const resetToken = jwt.sign(
            { userId, purpose: 'reset_password' },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );
        return res.json({ message: 'OTP verified.', resetToken });
    } catch (error) {
        console.error('[AUTH] verifyOtp error:', error.message);
        return res.status(500).json({ error: 'OTP verification failed.' });
    }
};

// ── POST /auth/google-signin/resend-otp ──────────────────────────────────────
const resendOtp = async (req, res) => {
    try {
        const { userId, type = 'verify_email' } = req.body;
        if (!userId) return res.status(400).json({ error: 'userId is required.' });

        const user = await User.findById(userId);
        if (!user) return res.status(404).json({ error: 'User not found.' });

        const otp = generateOTP();
        await OTP.deleteMany({ userId, type });
        await OTP.create({
            userId,
            email: user.email,
            otp,
            type,
            expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        });

        if (type === 'reset_password') {
            await sendPasswordResetOTP(user.email, user.name, otp);
        } else {
            await sendVerificationOTP(user.email, user.name, otp);
        }

        return res.json({ message: 'OTP resent successfully.' });
    } catch (error) {
        console.error('[AUTH] resendOtp error:', error.message);
        return res.status(500).json({ error: 'Failed to resend OTP.' });
    }
};

// ── POST /auth/google-signin/forgot-password ─────────────────────────────────
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: 'Email is required.' });

        const user = await User.findOne({ email: email.toLowerCase().trim() });

        // Always return 200 to prevent email enumeration attacks
        if (!user || user.authProvider === 'google') {
            return res.json({ message: 'If that email is registered, a reset code has been sent.' });
        }

        const otp = generateOTP();
        await OTP.deleteMany({ userId: user._id, type: 'reset_password' });
        await OTP.create({
            userId: user._id,
            email: user.email,
            otp,
            type: 'reset_password',
            expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        });

        await sendPasswordResetOTP(user.email, user.name, otp);

        console.log(`[AUTH] Password reset OTP sent to: ${user.email}`);
        return res.json({
            message: 'If that email is registered, a reset code has been sent.',
            userId: user._id,
        });
    } catch (error) {
        console.error('[AUTH] forgotPassword error:', error.message);
        return res.status(500).json({ error: 'Failed to send reset email.' });
    }
};

// ── POST /auth/google-signin/reset-password ───────────────────────────────────
const resetPassword = async (req, res) => {
    try {
        const { resetToken, newPassword } = req.body;
        if (!resetToken || !newPassword) {
            return res.status(400).json({ error: 'resetToken and newPassword are required.' });
        }
        if (newPassword.length < 8) {
            return res.status(400).json({ error: 'Password must be at least 8 characters.' });
        }

        let decoded;
        try {
            decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
        } catch {
            return res.status(400).json({ error: 'Reset token is invalid or expired.' });
        }

        if (decoded.purpose !== 'reset_password') {
            return res.status(400).json({ error: 'Invalid reset token.' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 12);
        const user = await User.findOneAndUpdate(
            { _id: decoded.userId },
            { $set: { password: hashedPassword } },
            { new: true }
        );
        if (!user) return res.status(404).json({ error: 'User not found.' });

        console.log(`[AUTH] Password reset for: ${user.email}`);
        return res.json({ message: 'Password reset successfully. Please sign in.' });
    } catch (error) {
        console.error('[AUTH] resetPassword error:', error.message);
        return res.status(500).json({ error: 'Password reset failed.' });
    }
};

// ── POST /auth/google-signin/google (existing — unchanged) ───────────────────
const googleAuth = async (req, res) => {
    try {
        const { idToken } = req.body;
        if (!idToken) return res.status(400).json({ error: 'idToken is required' });

        const audiences = [process.env.GOOGLE_CLIENT_ID, process.env.ANDROID_CLIENT_ID].filter(Boolean);
        if (audiences.length === 0) return res.status(500).json({ error: 'Server auth configuration error.' });

        const ticket = await client.verifyIdToken({ idToken, audience: audiences });
        const payload = ticket.getPayload();
        const { sub: googleId, email, name, picture: profilePicture } = payload;

        let user = await User.findOne({ googleId });
        if (!user) {
            user = await User.findOne({ email: email.toLowerCase() });
            if (user) {
                user = await User.findOneAndUpdate(
                    { email: email.toLowerCase() },
                    { $set: { googleId, profilePicture, isVerified: true } },
                    { new: true }
                );
            } else {
                user = await User.create({ name, email: email.toLowerCase(), googleId, profilePicture, authProvider: 'google', isVerified: true });
            }
        } else {
            user = await User.findOneAndUpdate({ googleId }, { $set: { profilePicture, isVerified: true } }, { new: true });
        }

        const token = signToken(user);
        console.log(`[AUTH] Google user signed in: ${user.email}`);
        return res.json({ token, user: userPayload(user) });
    } catch (error) {
        console.error('[AUTH] Google auth error:', error.message);
        return res.status(401).json({ error: 'Google token verification failed', detail: error.message });
    }
};

// ── GET /auth/google-signin/me ────────────────────────────────────────────────
const getMe = async (req, res) => {
    try {
        const user = await User.findOne({ _id: req.user.id }).select('name email profilePicture phone bio creatorScore authProvider isVerified');
        if (!user) return res.status(404).json({ error: 'User not found' });
        return res.json({ user });
    } catch (error) {
        console.error('[AUTH] getMe error:', error.message);
        return res.status(500).json({ error: 'Failed to fetch user profile' });
    }
};

// ── PUT /auth/google-signin/profile ──────────────────────────────────────────
const updateProfile = async (req, res) => {
    try {
        const { name, phone, bio } = req.body;
        const user = await User.findOneAndUpdate(
            { _id: req.user.id },
            { $set: { ...(name && { name }), ...(phone !== undefined && { phone }), ...(bio !== undefined && { bio }) } },
            { new: true }
        ).select('name email profilePicture phone bio creatorScore authProvider isVerified');

        if (!user) return res.status(404).json({ error: 'User not found' });
        console.log(`[AUTH] Profile updated for: ${user.email}`);
        return res.json({ user });
    } catch (error) {
        console.error('[AUTH] updateProfile error:', error.message);
        return res.status(500).json({ error: 'Failed to update profile' });
    }
};

// ── POST /auth/google-signin/logout ──────────────────────────────────────────
const logout = (req, res) => res.json({ success: true, message: 'Logged out successfully' });

// ── GET /auth/google-signin/web ──────────────────────────────────────────────
const webGoogleAuth = (req, res) => {
    const redirectUri = process.env.GOOGLE_WEB_REDIRECT_URI || 'https://creatoros-backend-rb5b.onrender.com/auth/google-signin/web/callback';
    const webClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET, redirectUri);
    const authorizeUrl = webClient.generateAuthUrl({ access_type: 'offline', scope: ['openid', 'email', 'profile'], prompt: 'select_account' });
    res.redirect(authorizeUrl);
};

// ── GET /auth/google-signin/web/callback ─────────────────────────────────────
const webGoogleCallback = async (req, res) => {
    const { code, error } = req.query;
    const frontendBase = process.env.FRONTEND_WEB_URL || 'http://localhost:3000';
    if (error || !code) return res.redirect(`${frontendBase}/?auth_error=${encodeURIComponent(error || 'cancelled')}`);

    try {
        const redirectUri = process.env.GOOGLE_WEB_REDIRECT_URI || 'https://creatoros-backend-rb5b.onrender.com/auth/google-signin/web/callback';
        const webClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID, process.env.GOOGLE_CLIENT_SECRET, redirectUri);
        const { tokens } = await webClient.getToken(code);
        const audiences = [process.env.GOOGLE_CLIENT_ID, process.env.ANDROID_CLIENT_ID].filter(Boolean);
        const ticket = await webClient.verifyIdToken({ idToken: tokens.id_token, audience: audiences });
        const payload = ticket.getPayload();
        const { sub: googleId, email, name, picture: profilePicture } = payload;

        let user = await User.findOne({ googleId });
        if (!user) {
            user = await User.findOne({ email: email.toLowerCase() });
            if (user) {
                user = await User.findOneAndUpdate({ email: email.toLowerCase() }, { $set: { googleId, profilePicture, isVerified: true } }, { new: true });
            } else {
                user = await User.create({ name, email: email.toLowerCase(), googleId, profilePicture, authProvider: 'google', isVerified: true });
            }
        } else {
            user = await User.findOneAndUpdate({ googleId }, { $set: { profilePicture, isVerified: true } }, { new: true });
        }

        const token = signToken(user);
        console.log(`[AUTH] Web user signed in: ${user.email}`);
        res.redirect(`${frontendBase}/?auth_token=${encodeURIComponent(token)}`);
    } catch (err) {
        console.error('[AUTH] Web callback error:', err.message);
        res.redirect(`${frontendBase}/?auth_error=${encodeURIComponent('auth_failed')}`);
    }
};

module.exports = {
    signup, signin, verifyOtp, resendOtp, forgotPassword, resetPassword,
    googleAuth, getMe, updateProfile, logout, webGoogleAuth, webGoogleCallback,
};
