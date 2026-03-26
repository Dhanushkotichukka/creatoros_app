const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');

// Existing mock endpoint for testing
router.post('/generate-script', (req, res) => {
    res.json({ script: "Here is your AI generated script!" });
});

// New Core AI Endpoints
router.post('/text-to-image', aiController.generateThumbnail);
router.post('/auto-caption', aiController.generateCaptions);
router.post('/analyze-thumbnail', aiController.analyzeThumbnail);
router.post('/my-ai/trends', aiController.getTrendingTopics);
router.post('/my-ai/generate-script', aiController.generateScript);
router.post('/master-ai/generate-batch', aiController.generateMasterScripts);

module.exports = router;
