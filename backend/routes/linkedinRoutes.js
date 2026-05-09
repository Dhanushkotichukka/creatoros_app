const express = require('express');
const router = express.Router();
const linkedinController = require('../controllers/linkedinController');
const authenticateToken = require('../middleware/authMiddleware');

// Protected: starts OAuth flow
router.get('/connect', authenticateToken, linkedinController.getLoginUrl);
router.get('/login', authenticateToken, linkedinController.getLoginUrl); // legacy alias

// Public: receives OAuth redirect from LinkedIn
router.get('/callback', linkedinController.handleCallback);

// Protected: per-user
router.get('/analytics', authenticateToken, linkedinController.getLinkedInAnalytics);
router.get('/status', authenticateToken, linkedinController.getStatus);
router.post('/disconnect', authenticateToken, linkedinController.disconnect);

module.exports = router;
