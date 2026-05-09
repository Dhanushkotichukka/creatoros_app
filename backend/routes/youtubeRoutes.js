const express = require('express');
const router = express.Router();
const youtubeController = require('../controllers/youtubeController');
const authenticateToken = require('../middleware/authMiddleware');

// Protected: starts OAuth — encodes userId in state
router.get('/connect', authenticateToken, youtubeController.getAuthUrl);

// Public: receives OAuth redirect from Google (no JWT available here)
router.get('/callback', youtubeController.handleCallback);

// Protected: per-user status/channel/disconnect
router.get('/channel', authenticateToken, youtubeController.getChannelInfo);
router.get('/status', authenticateToken, youtubeController.getStatus);
router.post('/disconnect', authenticateToken, youtubeController.disconnect);

// Legacy alias so any existing Flutter clients calling /login still work
router.get('/login', authenticateToken, youtubeController.getAuthUrl);

module.exports = router;
