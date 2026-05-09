const express = require('express');
const router = express.Router();
const metaController = require('../controllers/metaController');
const authenticateToken = require('../middleware/authMiddleware');

// Protected: starts OAuth flow — encodes userId in state
router.get('/connect', authenticateToken, metaController.getLoginUrl);
router.get('/login', authenticateToken, metaController.getLoginUrl); // legacy alias

// Public: receives OAuth redirect from Facebook
router.get('/callback', metaController.handleCallback);

// Protected: per-user status/analytics/disconnect
router.get('/instagram/analytics', authenticateToken, metaController.getInstagramAnalytics);
router.get('/facebook/analytics', authenticateToken, metaController.getFacebookAnalytics);
router.get('/status', authenticateToken, metaController.getStatus);
router.post('/disconnect', authenticateToken, metaController.disconnect);

module.exports = router;
