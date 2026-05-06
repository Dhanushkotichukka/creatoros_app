const express = require('express');
const router = express.Router();
const youtubeController = require('../controllers/youtubeController');

router.get('/login', youtubeController.getAuthUrl);
router.get('/callback', youtubeController.handleCallback);
router.get('/channel', youtubeController.getChannelInfo);
router.get('/status', youtubeController.getStatus);
router.post('/disconnect', youtubeController.disconnect);

module.exports = router;
