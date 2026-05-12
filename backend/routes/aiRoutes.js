const express = require('express');
const router = express.Router();
const aiService = require('../services/aiService');
const multer = require('multer');
const { body, validationResult } = require('express-validator');
const upload = multer({ dest: 'uploads/' }); // Temporary storage for transcription

// Middleware to check validation results
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ error: errors.array()[0].msg });
    }
    next();
};

// ─── AI LAB CORE ENDPOINTS (Multi-Brain Router) ──────────────────────────

// 1. Script Writer
router.post('/script', 
    body('topic').trim().notEmpty().withMessage('Topic is required'),
    validate,
    async (req, res) => {
    try {
        const { topic } = req.body;
        const result = await aiService.generateScript(topic);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate script' });
    }
});

// 2. AI Chat Assistant
router.post('/chat', 
    body('message').trim().notEmpty().withMessage('Message is required'),
    validate,
    async (req, res) => {
    try {
        const { message, context } = req.body;
        const result = await aiService.generateAIChat(message, context);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate chat response' });
    }
});

// 3. Hashtags & Metadata
router.post('/metadata', 
    body('topic').trim().notEmpty().withMessage('Topic is required'),
    validate,
    async (req, res) => {
    try {
        const { topic } = req.body;
        const result = await aiService.generateMetadata(topic);
        // Return hashtags at top-level so Flutter client can read json['hashtags']
        const parsed = typeof result === 'string' ? JSON.parse(result) : result;
        res.json({ hashtags: parsed?.hashtags || parsed?.title || result, data: parsed });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate metadata' });
    }
});

// 4. Analytics AI (Master AI)
router.post('/analyze', 
    body('analyticsData').notEmpty().withMessage('Analytics data is required'),
    validate,
    async (req, res) => {
    try {
        const { analyticsData } = req.body;
        const result = await aiService.analyzeChannelData(analyticsData);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to analyze data' });
    }
});

// 5. Transcribe Audio (Captions)
router.post('/transcribe', upload.single('audioFile'), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ error: 'Audio file is required' });
        const result = await aiService.transcribeAudio(req.file.path);
        
        // Clean up temp file
        const fs = require('fs');
        fs.unlinkSync(req.file.path);
        
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to transcribe audio' });
    }
});

// 6. Voice AI (TTS)
router.post('/voiceover', 
    body('text').trim().notEmpty().withMessage('Text is required'),
    validate,
    async (req, res) => {
    try {
        const { text } = req.body;
        const result = await aiService.generateVoiceover(text);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate voiceover' });
    }
});

// ─── LEGACY ENDPOINTS (Kept for backwards compatibility) ───────
const aiController = require('../controllers/aiController');
router.post('/my-ai/trends', aiController.getTrendingTopics);
router.post('/my-ai/trending-videos', aiController.getTrendingVideos);
router.post('/my-ai/extract-transcript', aiController.extractTranscript);
router.post('/my-ai/generate-script', aiController.generateScript);
router.post('/my-ai/modify-script', aiController.modifyScript);
router.post('/master-ai/analyze-channel', aiController.analyzeChannelInsights);

// This endpoint is called by the Flutter app's generateMasterScripts method
router.post('/master-ai/generate-batch', async (req, res) => {
    try {
        const { niche, targetAudience } = req.body;
        // Build a topic from niche + target audience and get AI script ideas
        const prompt = niche || targetAudience || 'Content Creation';
        const raw = await aiService.generateScript(prompt);
        const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
        // Return as 'scripts' array so Flutter reads json['scripts']
        const scripts = Array.isArray(parsed) ? parsed : [parsed];
        res.json({ scripts });
    } catch (e) {
        console.error('[MASTER-AI BATCH]', e.message);
        res.status(500).json({ error: 'Failed to generate batch scripts', scripts: [] });
    }
});

module.exports = router;
