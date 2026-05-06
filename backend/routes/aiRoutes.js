const express = require('express');
const router = express.Router();
const aiService = require('../services/aiService');
const multer = require('multer');
const upload = multer({ dest: 'uploads/' }); // Temporary storage for transcription

// ─── AI LAB CORE ENDPOINTS (Multi-Brain Router) ──────────────────────────

// 1. Script Writer
router.post('/script', async (req, res) => {
    try {
        const { topic } = req.body;
        if (!topic) return res.status(400).json({ error: 'Topic is required' });
        const result = await aiService.generateScript(topic);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate script' });
    }
});

// 2. AI Chat Assistant
router.post('/chat', async (req, res) => {
    try {
        const { message, context } = req.body;
        if (!message) return res.status(400).json({ error: 'Message is required' });
        const result = await aiService.generateAIChat(message, context);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate chat response' });
    }
});

// 3. Hashtags & Metadata
router.post('/metadata', async (req, res) => {
    try {
        const { topic } = req.body;
        if (!topic) return res.status(400).json({ error: 'Topic is required' });
        const result = await aiService.generateMetadata(topic);
        res.json({ data: result });
    } catch (e) {
        console.error(e);
        res.status(500).json({ error: 'Failed to generate metadata' });
    }
});

// 4. Analytics AI (Master AI)
router.post('/analyze', async (req, res) => {
    try {
        const { analyticsData } = req.body;
        if (!analyticsData) return res.status(400).json({ error: 'Analytics data is required' });
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
router.post('/voiceover', async (req, res) => {
    try {
        const { text } = req.body;
        if (!text) return res.status(400).json({ error: 'Text is required' });
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

module.exports = router;
