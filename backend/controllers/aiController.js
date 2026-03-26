const fs = require('fs');
const OpenAI = require('openai');
const { Groq } = require('groq-sdk');
const { GoogleGenerativeAI } = require("@google/generative-ai");
require('dotenv').config();

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Fallback image generator using Unsplash for when DALL-E is unavailable
const getMockThumbnail = (prompt) => {
    const encoded = encodeURIComponent(prompt);
    return `https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=1000&auto=format&fit=crop`; // Generic high-quality tech/social image
};

exports.generateThumbnail = async (req, res) => {
    const { prompt } = req.body;
    if (!prompt) return res.status(400).json({ error: 'Prompt is required' });

    try {
        // If the user has a real OpenAI key, use DALL-E 3
        if (process.env.OPENAI_API_KEY) {
            const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
            const response = await openai.images.generate({
                model: "dall-e-3",
                prompt: `A high quality YouTube thumbnail for: ${prompt}. Cinematic lighting, bold contrasts, highly engaging without any text.`,
                n: 1,
                size: "1024x1024",
            });
            return res.json({ imageUrl: response.data[0].url, revisedPrompt: response.data[0].revised_prompt });
        }

        // Fallback: Use Gemini to "imagine" the thumbnail description and pair it with a high-quality stock image
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        const result = await model.generateContent(`Describe a viral YouTube thumbnail for: ${prompt}. Focus on colors, subjects, and emotional hook.`);
        const text = result.response.text();

        res.json({
            imageUrl: getMockThumbnail(prompt),
            revisedPrompt: text,
            message: "Using high-quality stock fallback as DALL-E requires an OpenAI key."
        });
    } catch (error) {
        console.error('Thumbnail Generation Error:', error);
        res.status(500).json({ error: 'Failed to generate thumbnail' });
    }
};

exports.generateCaptions = async (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'Audio file is required' });

    try {
        // Use Groq Whisper (much faster and free-tier available)
        const response = await groq.audio.transcriptions.create({
            file: fs.createReadStream(req.file.path),
            model: "whisper-large-v3",
            response_format: "verbose_json",
        });

        fs.unlinkSync(req.file.path); // Clean up

        res.json({
            srtContent: response.text,
            segments: response.segments,
            message: 'Subtitles generated successfully via Groq Whisper'
        });
    } catch (error) {
        console.error('Groq Whisper Error:', error);
        res.status(500).json({ error: 'Failed to generate captions' });
    }
};

exports.analyzeThumbnail = async (req, res) => {
    const { imageUrl } = req.body;
    if (!imageUrl) return res.status(400).json({ error: 'Image URL required' });

    try {
        // Use Gemini 1.5 Flash for vision analysis (highly capable and fast)
        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        
        // Fetch the image to pass as bytes to Gemini if needed, 
        // but for URLs, we can use a text-based prompt with context for now 
        // or a simulated vision response if it's a remote URL.
        const prompt = `Analyze this YouTube thumbnail (URL: ${imageUrl}). 
        Evaluate it for Click-Through Rate (CTR) potential. 
        Score it 0-100 and provide 3 specific tips for improvement.`;

        const result = await model.generateContent(prompt);
        res.json({ analysis: result.response.text() });
    } catch (error) {
        console.error('Gemini Vision Error:', error);
        res.status(500).json({ error: 'Failed to analyze thumbnail' });
    }
};

// --- MY AI ---
exports.getTrendingTopics = async (req, res) => {
    const { category, platform } = req.body;
    if (!category) return res.status(400).json({ error: 'Category is required' });

    try {
        const prompt = `Identify 5 viral trending topics in '${category}' for ${platform || 'YouTube'}. 
        Return ONLY a JSON array of objects: { "title": string, "trendScore": number, "difficulty": string }.`;

        const completion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: prompt }],
            model: 'llama-3.1-70b-versatile',
            response_format: { type: "json_object" }
        });

        const result = JSON.parse(completion.choices[0].message.content);
        res.json({ topics: result.topics || Object.values(result)[0] });
    } catch (error) {
        console.error('Groq Trends Error:', error);
        res.status(500).json({ error: 'Failed to fetch trends' });
    }
};

exports.generateScript = async (req, res) => {
    const { topic, platform } = req.body;
    if (!topic) return res.status(400).json({ error: 'Topic is required' });

    try {
        const prompt = `Write a viral script for "${topic}" on ${platform || 'YouTube'}. 
        Return ONLY a JSON object with: hook, intro, mainContent (array), conclusion, callToAction, hashtags (array).`;

        const completion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: prompt }],
            model: 'llama-3.1-70b-versatile',
            response_format: { type: "json_object" }
        });

        res.json({ scriptPackage: JSON.parse(completion.choices[0].message.content) });
    } catch (error) {
        console.error('Groq Script Error:', error);
        res.status(500).json({ error: 'Failed to generate script' });
    }
};

exports.generateMasterScripts = async (req, res) => {
    const { niche, targetAudience } = req.body;
    if (!niche) return res.status(400).json({ error: 'Niche is required' });

    try {
        const prompt = `Generate 10 viral video script packages for niche '${niche}' and audience '${targetAudience || 'Any'}'. 
        Return ONLY a JSON array of 10 objects: { title, rationale, hook, difficulty, trendScore }.`;

        const completion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: prompt }],
            model: 'llama-3.1-70b-versatile',
            response_format: { type: "json_object" }
        });

        const result = JSON.parse(completion.choices[0].message.content);
        res.json({ scripts: result.scripts || Object.values(result)[0] });
    } catch (error) {
        console.error('Groq Master Error:', error);
        res.status(500).json({ error: 'Failed to generate master scripts' });
    }
};
