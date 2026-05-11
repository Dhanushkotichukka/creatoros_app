const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const {
    signup, signin, verifyOtp, resendOtp, forgotPassword, resetPassword,
    googleAuth, getMe, updateProfile, logout, webGoogleAuth, webGoogleCallback
} = require('../controllers/authController');
const authenticateToken = require('../middleware/authMiddleware');

// Rate limiter for auth endpoints — max 10 requests per 15 minutes per IP
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { error: 'Too many attempts. Please try again in 15 minutes.' },
    standardHeaders: true,
    legacyHeaders: false,
});

// ── Email + Password Auth ────────────────────────────────────────────────────
router.post('/signup', authLimiter, signup);
router.post('/signin', authLimiter, signin);
router.post('/verify-otp', authLimiter, verifyOtp);
router.post('/resend-otp', authLimiter, resendOtp);
router.post('/forgot-password', authLimiter, forgotPassword);
router.post('/reset-password', authLimiter, resetPassword);

// ── Google OAuth ─────────────────────────────────────────────────────────────
router.post('/google', authLimiter, googleAuth);
router.get('/web', webGoogleAuth);
router.get('/web/callback', webGoogleCallback);

// ── Protected ────────────────────────────────────────────────────────────────
router.get('/me', authenticateToken, getMe);
router.put('/profile', authenticateToken, updateProfile);
router.post('/logout', logout);

module.exports = router;
