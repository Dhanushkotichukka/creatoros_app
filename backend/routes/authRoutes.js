const express = require('express');
const router = express.Router();
const { googleAuth, getMe, updateProfile, logout } = require('../controllers/authController');
const authenticateToken = require('../middleware/authMiddleware');

// Public — Flutter sends Google idToken here
router.post('/google', googleAuth);

// Protected — returns current user profile
router.get('/me', authenticateToken, getMe);

// Protected — update editable profile fields (name, phone, bio)
router.put('/profile', authenticateToken, updateProfile);

// Public — client clears its own JWT
router.post('/logout', logout);

module.exports = router;
