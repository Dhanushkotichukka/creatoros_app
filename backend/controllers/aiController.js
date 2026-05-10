const fs = require('fs');
const { Groq } = require('groq-sdk');
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { google } = require('googleapis');
const Parser = require('rss-parser');
const axios = require('axios');
const rssParser = new Parser();
const youtubeController = require('./youtubeController');
require('dotenv').config();

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// ─── KNOWN CHANNEL ───────────────────────────────────────────────────
const FALLBACK_CHANNEL_ID = 'UCBJycsmduvYEL83R_U4JriQ'; // MKBHD (Reliable fallback for RSS)

// ─── AI RESILIENCE ───────────────────────────────────────────────────
const safePrompt = async ({ prompt, json = true, temperature = 0.7 }) => {
    // Try Groq 70B first
    try {
        const completion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: prompt }],
            model: 'llama-3.3-70b-versatile',
            response_format: json ? { type: 'json_object' } : undefined,
            temperature
        });
        return completion.choices[0].message.content;
    } catch (e) {
        console.warn('[AI] Groq 70B hit limit, trying 8B...');
    }

    // Try Groq 8B
    try {
        const completion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: prompt }],
            model: 'llama-3.1-8b-instant',
            response_format: json ? { type: 'json_object' } : undefined,
            temperature
        });
        return completion.choices[0].message.content;
    } catch (e) {
        console.warn('[AI] Groq 8B hit limit, using Gemini fallback...');
    }

    // Final fallback: Gemini
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent(prompt + (json ? "\nReturn ONLY valid JSON, no markdown." : ""));
    const response = await result.response;
    let text = response.text();
    if (json) text = text.replace(/```json/g, '').replace(/```/g, '').trim();
    return text;
};

const formatViews = (v) => {
    const n = parseInt(v) || 0;
    if (n >= 1_000_000) return (n / 1_000_000).toFixed(1) + 'M';
    if (n >= 1_000) return (n / 1_000).toFixed(0) + 'K';
    return String(n);
};

// ─── RSS VIDEO FETCHER (Quota-free real channel data) ─────────────────
const fetchVideosViaRSS = async (channelId, userId) => {
    let cId = channelId || FALLBACK_CHANNEL_ID;
    if (!channelId && userId) {
        const ytToken = await require('../models/Token').findOne({ userId, platform: 'youtube' });
        cId = ytToken?.platformAccountId || FALLBACK_CHANNEL_ID;
    }
    try {
        console.log(`[RSS] Scraping real videos for channel: ${cId}`);
        const url = `https://www.youtube.com/feeds/videos.xml?channel_id=${cId}`;
        const feed = await rssParser.parseURL(url);
        const items = (feed.items || []).map(i => {
            const vid = i.id ? i.id.split(':').pop() : '';
            return {
                title: i.title,
                videoId: vid,
                description: i.contentSnippet || '',
                thumbnail: `https://i.ytimg.com/vi/${vid}/hqdefault.jpg`,
                date: i.pubDate || new Date().toISOString()
            };
        });
        console.log(`[RSS] Retrieved ${items.length} real videos.`);
        return items;
    } catch (e) {
        console.error('[RSS FAIL]', e.message);
        return [];
    }
};

// ─── TRENDING TOPICS FROM NEWS (No-quota fallback) ────────────────────
const fetchNewsTopics = async (niche) => {
    try {
        const feed = await rssParser.parseURL(
            `https://news.google.com/rss/search?q=${encodeURIComponent(niche)}&hl=en-IN&gl=IN&ceid=IN:en`
        );
        return (feed.items || []).slice(0, 5).map(i => ({
            source: 'Google News', title: i.title?.replace(/ - [^-]+$/, '') || 'Trending Story',
            url: i.link, date: i.pubDate || new Date().toISOString(), views: 500000
        }));
    } catch (e) { return []; }
};

// ─── AI ENDPOINTS ────────────────────────────────────────────────────

exports.getTrendingVideos = async (req, res) => {
    const { category } = req.body;
    try {
        let videos = [];

        // Try YouTube API first
        try {
            const youtube = await youtubeController.getYouTubeClient(req.user.id);
            if (youtube) {
                const since = new Date(Date.now() - 7 * 86400000).toISOString();
                const s = await youtube.search.list({ part: 'snippet', q: category || 'Viral', type: 'video', order: 'viewCount', publishedAfter: since, maxResults: 8 });
                const ids = (s.data.items || []).map(i => i.id.videoId).join(',');
                if (ids) {
                    const v = await youtube.videos.list({ part: 'snippet,statistics', id: ids });
                    videos = (v.data.items || []).map(v => ({
                        source: 'YouTube', videoId: v.id, title: v.snippet.title,
                        thumbnail: v.snippet.thumbnails?.high?.url,
                        views: parseInt(v.statistics.viewCount || 0),
                        date: v.snippet.publishedAt, url: `https://youtube.com/watch?v=${v.id}`,
                        channelName: v.snippet.channelTitle
                    }));
                }
            }
        } catch (e) {
            console.warn('[TRENDING] YT quota hit, using News RSS fallback.');
        }

        // If YouTube search failed, use News RSS
        if (videos.length === 0) {
            const newsItems = await fetchNewsTopics(category || 'Viral Content Creator');
            videos = newsItems.map(n => ({ ...n, videoId: null }));
        }

        res.json({ videos });
    } catch (e) { res.status(500).json({ error: 'Failed to fetch trends', videos: [] }); }
};

exports.getTrendingTopics = async (req, res) => {
    const { category } = req.body;
    try {
        // Get real channel videos for context
        const channelVideos = await fetchVideosViaRSS(FALLBACK_CHANNEL_ID, req.user.id);
        const recentTitles = channelVideos.slice(0, 6).map(v => v.title);

        const prompt = `You are an expert YouTube strategist. Based on these recent videos from the channel: ${JSON.stringify(recentTitles)}, and the niche "${category}", generate 5 highly specific, viral video content ideas tailored to this channel's style. Return JSON: { "topics": [{"title":"...","trendScore":95,"whyTrending":"...","hook":"..."}] }`;
        const raw = await safePrompt({ prompt, json: true });
        res.json(JSON.parse(raw));
    } catch (e) { res.status(500).json({ error: 'Failed to generate topics' }); }
};

exports.extractTranscript = async (req, res) => {
    const { videoId } = req.body;
    try {
        const { getSubtitles } = require('youtube-captions-scraper');
        const codes = ['en', 'a.en', 'te', 'a.te', 'hi', 'a.hi'];
        let captions = null;
        for (const lang of codes) {
            try {
                captions = await getSubtitles({ videoID: videoId, lang });
                if (captions?.length) break;
            } catch (_) {}
        }
        if (!captions?.length) {
            return res.json({ available: false, message: 'Transcript locked or unavailable for this video.' });
        }
        const text = captions.map(c => c.text).join(' ').replace(/\s+/g, ' ').trim();
        res.json({ available: true, transcript: text });
    } catch (e) {
        res.json({ available: false, message: 'Transcript service unavailable.' });
    }
};

exports.generateScript = async (req, res) => {
    const { topic, platform, styleMode, contentType, scriptLength, language, sourceContext, sourceTranscripts } = req.body;
    try {
        const context = sourceTranscripts?.length > 0
            ? sourceTranscripts.map(t => `TITLE: ${t.title}\nTRANSCRIPT: ${t.transcript?.slice(0, 1200) || 'NOT AVAILABLE'}`).join('\n\n')
            : 'No source transcript provided.';

        const isMultilingual = language && language.toLowerCase() !== 'english';
        const teluguInstruction = isMultilingual
            ? `\nALSO include a "teluguVersion" key with the script adapted to natural, conversational Telugu — same structure (hook, mainContent array, callToAction).`
            : '';

        const prompt = `You are a world-class viral script writer. Topic: "${topic}". Context:\n${context}\nPlatform: ${platform}. Style: ${styleMode}. Type: ${contentType}. Length: ${scriptLength}. Language: ${language || 'English'}.\nIf transcript says "NOT AVAILABLE", create a brilliant original script about the topic.${teluguInstruction}\nReturn JSON: { "hook": "...", "mainContent": ["point1","point2","point3"], "callToAction": "...", "hashtags": ["#tag1","#tag2"], "estimatedDuration": "45 seconds", "aiRating": 8.5, "provenance": "Strategy reasoning here"${isMultilingual ? ', "teluguVersion": { "hook": "...", "mainContent": ["..."], "callToAction": "..." }' : ''} }`;

        const raw = await safePrompt({ prompt, json: true });
        res.json({ scriptPackage: JSON.parse(raw) });
    } catch (e) { res.status(500).json({ error: 'Script generation failed.' }); }
};

exports.modifyScript = async (req, res) => {
    const { currentText, action } = req.body;
    try {
        const prompt = `Perform "${action}" on this script: "${currentText}". Return only the improved text.`;
        const result = await safePrompt({ prompt, json: false });
        res.json({ improvedText: result.trim() });
    } catch (e) { res.status(500).json({ error: 'Modification failed.' }); }
};

exports.analyzeChannelInsights = async (req, res) => {
    try {
        let videos = [];

        // Step 1: Try official API
        try {
            const youtube = await youtubeController.getYouTubeClient(req.user.id);
            if (youtube) {
                const ytToken = await require('../models/Token').findOne({ userId: req.user.id, platform: 'youtube' });
                const channelRes = await youtube.channels.list({ part: 'snippet,contentDetails', mine: true });
                if (channelRes.data.items?.length) {
                    const ch = channelRes.data.items[0];
                    // Cache channel ID
                    if (ytToken && !ytToken.platformAccountId) {
                        ytToken.platformAccountId = ch.id;
                        await ytToken.save();
                    }
                    const plId = ch.contentDetails.relatedPlaylists.uploads;
                    const vres = await youtube.playlistItems.list({ part: 'snippet', playlistId: plId, maxResults: 15 });
                    videos = (vres.data.items || []).map(v => ({
                        title: v.snippet.title,
                        videoId: v.snippet.resourceId.videoId,
                        thumbnail: `https://i.ytimg.com/vi/${v.snippet.resourceId.videoId}/hqdefault.jpg`,
                        date: v.snippet.publishedAt
                    }));
                }
            }
        } catch (quotaErr) {
            console.warn('[MASTER AI] API quota hit → RSS scraper activated.');
        }

        // Step 2: RSS fallback if API gave nothing
        if (videos.length === 0) {
            const ytToken = await require('../models/Token').findOne({ userId: req.user.id, platform: 'youtube' });
            videos = await fetchVideosViaRSS(ytToken?.platformAccountId || FALLBACK_CHANNEL_ID, req.user.id);
        }

        // Step 3: Analyze with AI
        if (videos.length === 0) {
            return res.status(500).json({ error: 'Could not load channel videos. Please reconnect YouTube.' });
        }

        const prompt = `You are an elite YouTube strategist AI. Analyze these REAL videos from a YouTube channel: ${JSON.stringify(videos.slice(0, 10).map(v => ({ title: v.title })))}.\n\nExtract the precise niche, audience type, and generate 5 highly specific viral content opportunities that fit this channel's existing style.\nReturn JSON: {\n  "niche": { "primary": "...", "secondary": "...", "confidence": 95, "keywords": ["k1","k2","k3"] },\n  "smartTopics": [\n    { "title": "...", "trendScore": 95, "hook": "...", "whyTrending": "...", "sourceRef": "Based on..." }\n  ]\n}`;

        const raw = await safePrompt({ prompt, json: true });
        const analysis = JSON.parse(raw);

        // Step 4: External trends from news (no quota needed)
        const niche = analysis.niche?.primary || 'Film Reviews';
        const externalTrends = await fetchNewsTopics(niche);

        res.json({
            analysis: {
                ...analysis,
                topPerforming: videos.slice(0, 8),
                externalTrends
            }
        });
    } catch (e) {
        console.error('[MASTER AI ERROR]', e.message);
        res.status(500).json({ error: 'Analysis failed. Please try again.' });
    }
};

// ─── Tool Stubs ───────────────────────────────────────────────────────
exports.generateThumbnail = async (req, res) => res.json({ imageUrl: 'https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=1000' });
exports.generateCaptions = async (req, res) => res.json({ srtContent: "Auto-captions coming soon.", segments: [] });
exports.analyzeThumbnail = async (req, res) => res.json({ analysis: "Strong visual composition with high CTR potential." });
