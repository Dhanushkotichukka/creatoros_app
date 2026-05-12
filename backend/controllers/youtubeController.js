const { google } = require('googleapis');
const { Token } = require('../models');
require('dotenv').config();

const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    'https://creatoros-backend-rb5b.onrender.com/auth/youtube/callback'
);

// Refresh-token listener — updates DB record if token auto-refreshes
oauth2Client.on('tokens', async (tokens) => {
    console.log('[YT] Auto-refresh: new tokens received.');
    // The userId is set on the client before each request — stored on the client object itself
    if (oauth2Client._currentUserId && tokens.access_token) {
        try {
            await Token.findOneAndUpdate(
                { userId: oauth2Client._currentUserId, platform: 'youtube' },
                { accessToken: tokens.access_token, ...(tokens.refresh_token && { refreshToken: tokens.refresh_token }) },
                { new: true }
            );
        } catch (e) { console.error('[YT] Failed to update refreshed token:', e.message); }
    }
});

// Build an authenticated YouTube client for a specific user
async function getYouTubeClient(userId) {
    const tokenDoc = await Token.findOne({ userId, platform: 'youtube' });
    if (!tokenDoc) return null;
    oauth2Client._currentUserId = userId;
    oauth2Client.setCredentials({
        access_token: tokenDoc.accessToken,
        refresh_token: tokenDoc.refreshToken,
    });
    return google.youtube({ version: 'v3', auth: oauth2Client });
}

async function getYouTubeAnalyticsClient(userId) {
    const tokenDoc = await Token.findOne({ userId, platform: 'youtube' });
    if (!tokenDoc) return null;
    oauth2Client._currentUserId = userId;
    oauth2Client.setCredentials({
        access_token: tokenDoc.accessToken,
        refresh_token: tokenDoc.refreshToken,
    });
    return google.youtubeAnalytics({ version: 'v2', auth: oauth2Client });
}

exports.getYouTubeClient = getYouTubeClient;
exports.getYouTubeAnalyticsClient = getYouTubeAnalyticsClient;

// GET /auth/youtube/connect — protected, encodes userId in OAuth state
exports.getAuthUrl = (req, res) => {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ error: 'Not authenticated' });

    const state = Buffer.from(userId.toString()).toString('base64');
    const scopes = [
        'https://www.googleapis.com/auth/youtube.readonly',
        'https://www.googleapis.com/auth/youtube.upload',
        'https://www.googleapis.com/auth/yt-analytics.readonly',
        'https://www.googleapis.com/auth/yt-analytics-monetary.readonly',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email'
    ];
    const url = oauth2Client.generateAuthUrl({ access_type: 'offline', scope: scopes, prompt: 'consent', state });
    res.json({ url });
};

// GET /auth/youtube/callback — public (browser redirect from Google)
exports.handleCallback = async (req, res) => {
    const { code, state } = req.query;
    if (!code || !state) return res.status(400).send('Missing code or state');

    let userId;
    try {
        userId = Buffer.from(state, 'base64').toString('utf8');
    } catch {
        return res.status(400).send('Invalid state parameter');
    }

    try {
        const { tokens } = await oauth2Client.getToken(code);
        oauth2Client.setCredentials(tokens);

        // Fetch channel info
        let channelId, channelName, avatar, uploadsPlaylistId;
        try {
            const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
            const ytResponse = await youtube.channels.list({ part: 'snippet,contentDetails', mine: true });
            if (ytResponse.data.items?.length) {
                const channel = ytResponse.data.items[0];
                channelId = channel.id;
                channelName = channel.snippet.title;
                avatar = channel.snippet.thumbnails?.default?.url;
                uploadsPlaylistId = channel.contentDetails?.relatedPlaylists?.uploads;
            }
        } catch (e) {
            console.warn('[YT] Channel API error, falling back to userinfo:', e.message);
            try {
                const oauth2 = google.oauth2({ auth: oauth2Client, version: 'v2' });
                const userInfo = await oauth2.userinfo.get();
                channelName = userInfo.data.name || 'Connected Creator';
                avatar = userInfo.data.picture;
            } catch (err) {
                console.error('[YT] Userinfo also failed:', err.message);
            }
        }

        // Upsert token in MongoDB
        await Token.findOneAndUpdate(
            { userId, platform: 'youtube' },
            {
                userId,
                platform: 'youtube',
                accessToken: tokens.access_token,
                refreshToken: tokens.refresh_token || undefined,
                expiresAt: tokens.expiry_date ? new Date(tokens.expiry_date) : undefined,
                platformAccountId: channelId,
                platformAccountName: channelName,
                scopes: ['youtube'],
                ...(avatar && { avatar }),
                ...(uploadsPlaylistId && { uploadsPlaylistId }),
            },
            { upsert: true, returnDocument: 'after' }
        );

        console.log(`[YT] Token saved for userId=${userId}, channel=${channelName}`);

        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#FF0000; font-size:32px;">▶️ YouTube Linked!</h1>
                <p style="font-size:18px; color:#555;">Channel <strong>${channelName || 'Unknown'}</strong> connected successfully.</p>
                <script>setTimeout(() => { window.location.href = "creatoros://auth/success"; setTimeout(() => window.close(), 1000); }, 1000);</script>
              </div>
            </body>
            </html>
        `);
    } catch (error) {
        console.error('[YT] Callback error:', error.message);
        res.status(500).send('YouTube authentication failed');
    }
};

// GET /auth/youtube/status — protected
exports.getStatus = async (req, res) => {
    try {
        const tokenDoc = await Token.findOne({ userId: req.user.id, platform: 'youtube' });
        if (!tokenDoc) return res.json({ connected: false });
        res.json({
            connected: true,
            name: tokenDoc.platformAccountName,
            avatar: tokenDoc.avatar,
            id: tokenDoc.platformAccountId,
        });
    } catch (e) {
        res.status(500).json({ error: 'Failed to get YouTube status' });
    }
};

// GET /auth/youtube/channel — protected
exports.getChannelInfo = async (req, res) => {
    try {
        const youtube = await getYouTubeClient(req.user.id);
        if (!youtube) return res.status(401).json({ error: 'YouTube not connected' });
        const response = await youtube.channels.list({ part: 'snippet,contentDetails,statistics', mine: true });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: 'Failed to get channel info' });
    }
};

// Publish — called from publishController with userId
exports.publishToYouTube = async (mediaPath, metadata, userId) => {
    const youtube = await getYouTubeClient(userId);
    if (!youtube) throw new Error('YouTube not connected');
    const fs = require('fs');
    const response = await youtube.videos.insert({
        part: 'snippet,status',
        requestBody: {
            snippet: { title: metadata.title || 'New Video', description: metadata.description || '', tags: metadata.hashtags || [] },
            status: { privacyStatus: metadata.privacyStatus || 'public', madeForKids: false },
        },
        media: { body: fs.createReadStream(mediaPath) },
    });
    return { success: true, platform: 'YouTube', id: response.data.id };
};

// POST /auth/youtube/disconnect — protected
exports.disconnect = async (req, res) => {
    try {
        await Token.findOneAndDelete({ userId: req.user.id, platform: 'youtube' });
        res.json({ success: true, message: 'YouTube disconnected' });
    } catch (e) {
        res.status(500).json({ error: 'Failed to disconnect YouTube' });
    }
};
