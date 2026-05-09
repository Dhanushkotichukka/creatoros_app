const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { Token } = require('../models');
require('dotenv').config();

const APP_ID = process.env.META_APP_ID;
const APP_SECRET = process.env.META_APP_SECRET;
const REDIRECT_URI = 'https://creatoros-backend-rb5b.onrender.com/auth/meta/callback';

// ─── Resolve Instagram Business Account from a Meta access token ───────────
async function resolveIGAccount(accessToken) {
    try {
        const userRes = await axios.get(`https://graph.facebook.com/v19.0/me?fields=name,id&access_token=${accessToken}`);
        console.log(`[META] Authenticated User: ${userRes.data.name} (ID: ${userRes.data.id})`);

        let pages = [];

        // Probe /me/accounts
        const accRes = await axios.get(`https://graph.facebook.com/v19.0/me/accounts?fields=instagram_business_account,name,tasks,category&access_token=${accessToken}`);
        pages = accRes.data.data || [];

        // Direct IG probe if no pages with IG
        if (pages.length === 0 || !pages.some(p => p.instagram_business_account)) {
            try {
                const igAccRes = await axios.get(`https://graph.facebook.com/v19.0/me?fields=instagram_accounts{id,username,name,profile_picture_url},instagram_business_account{id,username,name,profile_picture_url}&access_token=${accessToken}`);
                const igAccounts = igAccRes.data.instagram_accounts?.data || [];
                if (igAccRes.data.instagram_business_account) igAccounts.push(igAccRes.data.instagram_business_account);
                for (const igAcc of igAccounts) {
                    pages.push({ name: igAcc.name || igAcc.username, instagram_business_account: { id: igAcc.id }, category: 'DIRECT_IG' });
                }
            } catch (e) { console.warn('[META] Direct IG probe failed:', e.message); }
        }

        const igPages = pages.filter(p => p.instagram_business_account);
        if (igPages.length === 0) return null;

        const { page, igId } = { page: igPages[0], igId: igPages[0].instagram_business_account.id };
        const igInfo = await axios.get(`https://graph.facebook.com/v19.0/${igId}?fields=username,name,profile_picture_url&access_token=${accessToken}`);
        return {
            igAccountId: igId,
            igUsername: igInfo.data.username,
            igName: igInfo.data.name,
            igAvatar: igInfo.data.profile_picture_url,
        };
    } catch (err) {
        console.error('[META] resolveIGAccount error:', err.message);
        return null;
    }
}

exports.resolveIGAccount = resolveIGAccount;

// GET /auth/meta/connect — protected, encodes userId in state
exports.getLoginUrl = (req, res) => {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Not authenticated' });

    const state = Buffer.from(userId.toString()).toString('base64');
    const scopes = [
        'instagram_basic', 'instagram_content_publish', 'instagram_manage_comments',
        'instagram_manage_insights', 'pages_show_list', 'pages_read_engagement',
        'pages_manage_posts', 'public_profile', 'business_management'
    ];
    const url = `https://www.facebook.com/v19.0/dialog/oauth?client_id=${APP_ID}&redirect_uri=${REDIRECT_URI}&scope=${scopes.join(',')}&response_type=code&state=${state}`;
    res.json({ url });
};

// GET /auth/meta/callback — public (browser redirect from Facebook)
exports.handleCallback = async (req, res) => {
    const { code, state } = req.query;
    if (!code) return res.status(400).send('No code provided');

    let userId;
    try {
        userId = state ? Buffer.from(state, 'base64').toString('utf8') : null;
    } catch { userId = null; }

    try {
        const tokenResponse = await axios.get(
            `https://graph.facebook.com/v19.0/oauth/access_token?client_id=${APP_ID}&redirect_uri=${REDIRECT_URI}&client_secret=${APP_SECRET}&code=${code}`
        );
        const accessToken = tokenResponse.data.access_token;

        const igData = await resolveIGAccount(accessToken);

        if (userId) {
            // Save token to DB
            await Token.findOneAndUpdate(
                { userId, platform: 'meta' },
                {
                    userId,
                    platform: 'meta',
                    accessToken,
                    platformAccountId: igData?.igAccountId,
                    platformAccountName: igData?.igUsername || igData?.igName,
                    ...(igData?.igAvatar && { avatar: igData.igAvatar }),
                    // Store IG-specific data in platformMetadata field on token
                    igAccountId: igData?.igAccountId,
                    igUsername: igData?.igUsername,
                    igName: igData?.igName,
                    igAvatar: igData?.igAvatar,
                },
                { upsert: true, new: true }
            );
            console.log(`[META] Token saved for userId=${userId}, IG=@${igData?.igUsername}`);
        } else {
            console.warn('[META] No userId in state — token NOT saved to DB');
        }

        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#1877F2; font-size:32px;">📷 Meta Connected!</h1>
                <p style="font-size:18px; color:#555;">Welcome, ${igData?.igName || igData?.igUsername || 'Creator'}!</p>
                <p style="color:#888;">Redirecting back to CreatorOS...</p>
                <a href="creatoros://auth/success" style="display:inline-block; margin-top:20px; padding:12px 24px; background:#1877F2; color:white; text-decoration:none; border-radius:8px; font-weight:bold;">Return to App</a>
                <script>setTimeout(() => { window.location.href = "creatoros://auth/success"; setTimeout(() => window.close(), 1000); }, 1000);</script>
              </div>
            </body>
            </html>
        `);
    } catch (error) {
        console.error('[META] Auth Error:', error.response?.data || error.message);
        res.status(500).send('Authentication failed');
    }
};

// GET /auth/meta/status — protected
exports.getStatus = async (req, res) => {
    try {
        const tokenDoc = await Token.findOne({ userId: req.user.id, platform: 'meta' });
        if (!tokenDoc) return res.json({ connected: false });

        // Optionally re-resolve if igAccountId missing
        if (!tokenDoc.igAccountId && tokenDoc.accessToken) {
            const igData = await resolveIGAccount(tokenDoc.accessToken);
            if (igData) {
                await Token.findOneAndUpdate({ _id: tokenDoc._id }, { igAccountId: igData.igAccountId, igUsername: igData.igUsername, igName: igData.igName, igAvatar: igData.igAvatar });
                return res.json({ connected: true, username: igData.igUsername, name: igData.igName, avatar: igData.igAvatar });
            }
        }

        res.json({
            connected: true,
            username: tokenDoc.igUsername,
            name: tokenDoc.igName,
            avatar: tokenDoc.igAvatar,
        });
    } catch (e) {
        res.status(500).json({ error: 'Failed to get Meta status' });
    }
};

// GET /auth/meta/instagram/analytics — protected
exports.getInstagramAnalytics = async (req, res) => {
    const { igAccountId } = req.query;
    try {
        const tokenDoc = await Token.findOne({ userId: req.user.id, platform: 'meta' });
        if (!tokenDoc) return res.status(401).json({ error: 'Meta not connected' });
        const accessToken = tokenDoc.accessToken;
        const igId = igAccountId || tokenDoc.igAccountId;

        const response = await axios.get(`https://graph.facebook.com/v19.0/${igId}/insights`, {
            params: { metric: 'impressions,reach,profile_views', period: 'day', metric_type: 'total_value', access_token: accessToken }
        });
        const mediaResponse = await axios.get(`https://graph.facebook.com/v19.0/${igId}/media`, {
            params: { fields: 'id,caption,media_type,media_url,thumbnail_url,like_count,comments_count,timestamp,insights.metric(impressions,reach,engagement)', access_token: accessToken, limit: 10 }
        });
        res.json({ platform: 'Instagram', dailyInsights: response.data.data, recentMedia: mediaResponse.data.data });
    } catch (error) {
        console.error('[META] IG Analytics Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to fetch Instagram analytics' });
    }
};

// GET /auth/meta/facebook/analytics — protected
exports.getFacebookAnalytics = async (req, res) => {
    const { pageId } = req.query;
    try {
        const tokenDoc = await Token.findOne({ userId: req.user.id, platform: 'meta' });
        if (!tokenDoc) return res.status(401).json({ error: 'Meta not connected' });

        const response = await axios.get(`https://graph.facebook.com/v19.0/${pageId}/insights`, {
            params: { metric: 'page_impressions_unique,page_engaged_users,page_post_engagements', period: 'day', access_token: tokenDoc.accessToken }
        });
        res.json({ platform: 'Facebook', pageInsights: response.data.data });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch Facebook analytics' });
    }
};

// Publish — called from publishController with userId
exports.publishToInstagram = async (mediaUrls, metadata, userId) => {
    const tokenDoc = await Token.findOne({ userId, platform: 'meta' });
    if (!tokenDoc || !tokenDoc.igAccountId) throw new Error('Instagram not connected');

    const accessToken = tokenDoc.accessToken;
    const igId = tokenDoc.igAccountId;

    const urls = Array.isArray(mediaUrls) ? mediaUrls : [mediaUrls];
    if (urls.length === 0) throw new Error('No media URLs provided');

    const isVideo = (url) => {
        const p = url.toLowerCase().split('?')[0];
        const ext = p.split('.').pop();
        return ['mp4', 'mov', 'avi', 'webm', 'mkv', 'wmv'].includes(ext);
    };

    const postType = (metadata.contentType || 'Post').toUpperCase();
    const titlePart = metadata.title ? `${metadata.title.toUpperCase()}\n\n` : '';
    const descPart = metadata.description ? `${metadata.description}\n\n` : '';
    const hashtagsPart = (metadata.hashtags?.length > 0) ? metadata.hashtags.map(t => t.startsWith('#') ? t : `#${t}`).join(' ') : '';
    const unifiedCaption = (postType === 'STORY') ? '' : `${titlePart}${descPart}${hashtagsPart}`.trim();

    const pollStatus = async (creationId, isVid = false) => {
        let attempts = 0;
        while (attempts < 30) {
            const fields = isVid ? 'status_code,video_status' : 'status_code';
            const r = await axios.get(`https://graph.facebook.com/v19.0/${creationId}`, { params: { fields, access_token: accessToken } });
            const status = r.data.status_code;
            if (status === 'FINISHED') return true;
            if (status === 'ERROR') throw new Error(`Instagram processing failed: ${r.data.video_status?.error_description || status}`);
            await new Promise(res => setTimeout(res, 10000));
            attempts++;
        }
        throw new Error('Video processing timed out on Meta side');
    };

    // STORY
    if (postType === 'STORY') {
        const url = urls[0]; const isVid = isVideo(url);
        const params = { media_type: 'STORIES', access_token: accessToken };
        if (isVid) params.video_url = url; else params.image_url = url;
        const r = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params });
        await pollStatus(r.data.id);
        const pub = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media_publish`, null, { params: { creation_id: r.data.id, access_token: accessToken } });
        return { success: true, platform: 'Instagram', id: pub.data.id, postType: 'STORY' };
    }

    // CAROUSEL
    if (urls.length > 1) {
        const itemIds = [];
        for (const url of urls) {
            const isVid = isVideo(url);
            const p = { is_carousel_item: true, access_token: accessToken };
            if (isVid) { p.video_url = url; p.media_type = 'VIDEO'; } else { p.image_url = url; }
            const r = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params: p });
            itemIds.push(r.data.id);
        }
        for (let i = 0; i < itemIds.length; i++) await pollStatus(itemIds[i], isVideo(urls[i]));
        const carRes = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params: { media_type: 'CAROUSEL', children: itemIds.join(','), caption: unifiedCaption, access_token: accessToken } });
        await pollStatus(carRes.data.id, false);
        await new Promise(r => setTimeout(r, 2000));
        const pub = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media_publish`, null, { params: { creation_id: carRes.data.id, access_token: accessToken } });
        return { success: true, platform: 'Instagram', id: pub.data.id, postType: 'CAROUSEL' };
    }

    // SINGLE
    const url = urls[0]; const isVid = isVideo(url);
    const params = { caption: unifiedCaption, access_token: accessToken };
    if (isVid) { params.video_url = url; params.media_type = 'REELS'; params.share_to_feed = true; } else { params.image_url = url; }
    const r = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params });
    await pollStatus(r.data.id, isVid);
    await new Promise(res => setTimeout(res, 2000));
    const pub = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media_publish`, null, { params: { creation_id: r.data.id, access_token: accessToken } });
    return { success: true, platform: 'Instagram', id: pub.data.id, postType: isVid ? 'REEL' : 'POST' };
};

// POST /auth/meta/disconnect — protected
exports.disconnect = async (req, res) => {
    try {
        await Token.findOneAndDelete({ userId: req.user.id, platform: 'meta' });
        res.json({ success: true, message: 'Meta disconnected' });
    } catch (e) {
        res.status(500).json({ error: 'Failed to disconnect Meta' });
    }
};
