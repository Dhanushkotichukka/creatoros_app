const express = require('express');
const router = express.Router();
const metaController = require('../controllers/metaController');

router.get('/login', metaController.getLoginUrl);
router.get('/callback', metaController.handleCallback);
router.get('/instagram/analytics', metaController.getInstagramAnalytics);
router.get('/facebook/analytics', metaController.getFacebookAnalytics);
router.get('/status', metaController.getStatus);
router.post('/disconnect', metaController.disconnect);

module.exports = router;
