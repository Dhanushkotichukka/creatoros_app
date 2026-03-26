const express = require('express');
const router = express.Router();
const linkedinController = require('../controllers/linkedinController');

router.get('/login', linkedinController.getLoginUrl);
router.get('/callback', linkedinController.handleCallback);
router.get('/analytics', linkedinController.getLinkedInAnalytics);
router.get('/status', linkedinController.getStatus);
router.post('/disconnect', linkedinController.disconnect);

module.exports = router;
