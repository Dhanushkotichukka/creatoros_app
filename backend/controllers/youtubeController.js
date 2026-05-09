const { google } = require('googleapis');
const Token = require('../models/Token');
require('dotenv').config();

const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    'http://localhost:3000/auth/youtube/callback'
);

// Assuming a default userId for now, this should ideally come from auth context
const DEFAULT_USER_ID = 'default-user-id';

// Helper to get youtube token for a user
async function getTokens(userId = DEFAULT_USER_ID) {
    return await Token.findOne({ userId, platform: 'youtube' });
}

// ONE-TIME LISTENER setup to avoid memory leaks
oauth2Client.on('tokens', async (tokens) => {
    console.log('[AUTH] New YouTube tokens received.');
    const userId = DEFAULT_USER_ID; // Should come from context or state
    const existingToken = await Token.findOne({ userId, platform: 'youtube' });
    if (existingToken) {
        if (tokens.refresh_token) existingToken.refreshToken = tokens.refresh_token;
        if (tokens.access_token) existingToken.accessToken = tokens.access_token;
        await existingToken.save();
    } else {
        await Token.create({
            userId,
            platform: 'youtube',
            accessToken: tokens.access_token,
            refreshToken: tokens.refresh_token || '',
        });
    }
});

async function getYouTubeClient(userId = DEFAULT_USER_ID) {
    const tokenDoc = await getTokens(userId);
    if (!tokenDoc || !tokenDoc.accessToken) return null;
    oauth2Client.setCredentials({
        access_token: tokenDoc.accessToken,
        refresh_token: tokenDoc.refreshToken
    });
    return google.youtube({ version: 'v3', auth: oauth2Client });
}

async function getYouTubeAnalyticsClient(userId = DEFAULT_USER_ID) {
    const tokenDoc = await getTokens(userId);
    if (!tokenDoc || !tokenDoc.accessToken) return null;
    oauth2Client.setCredentials({
        access_token: tokenDoc.accessToken,
        refresh_token: tokenDoc.refreshToken
    });
    return google.youtubeAnalytics({ version: 'v2', auth: oauth2Client });
}

exports.getYouTubeClient = getYouTubeClient;
exports.getYouTubeAnalyticsClient = getYouTubeAnalyticsClient;

exports.getAuthUrl = (req, res) => {
    const scopes = [
        'https://www.googleapis.com/auth/youtube.readonly',
        'https://www.googleapis.com/auth/youtube.upload',
        'https://www.googleapis.com/auth/yt-analytics.readonly',
        'https://www.googleapis.com/auth/yt-analytics-monetary.readonly',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email'
    ];
    const url = oauth2Client.generateAuthUrl({ access_type: 'offline', scope: scopes, prompt: 'consent' });
    res.redirect(url);
};

exports.handleCallback = async (req, res) => {
    const { code } = req.query;
    try {
        const { tokens } = await oauth2Client.getToken(code);
        oauth2Client.setCredentials(tokens);

        let ytChannelId = null;
        let ytChannelName = null;
        let ytAvatar = null;
        let ytUploadsPlaylistId = null;

        try {
            const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
            const ytResponse = await youtube.channels.list({ part: 'snippet,contentDetails', mine: true });
            if (ytResponse.data.items?.length) {
                const channel = ytResponse.data.items[0];
                ytChannelId = channel.id;
                ytChannelName = channel.snippet.title;
                ytAvatar = channel.snippet.thumbnails.default.url;
                ytUploadsPlaylistId = channel.contentDetails.relatedPlaylists.uploads;
            }
        } catch (e) { 
            console.warn('[YT] Profile API quota hit. Falling back to Google Profile for avatar:', e.message); 
            try {
                const oauth2 = google.oauth2({ auth: oauth2Client, version: 'v2' });
                const userInfo = await oauth2.userinfo.get();
                ytChannelName = userInfo.data.name || 'Connected Creator';
                ytAvatar = userInfo.data.picture;
            } catch (err) {
                console.error('[YT] Both Profile and UserInfo failed:', err.message);
            }
        }

        const userId = DEFAULT_USER_ID; // Or req.user.id in a real app
        const existingToken = await Token.findOne({ userId, platform: 'youtube' });
        if (existingToken) {
            existingToken.accessToken = tokens.access_token;
            existingToken.refreshToken = tokens.refresh_token || existingToken.refreshToken;
            existingToken.platformAccountId = ytChannelId;
            existingToken.platformAccountName = ytChannelName;
            existingToken.profileAvatar = ytAvatar;
            existingToken.extraData = { ytUploadsPlaylistId };
            await existingToken.save();
        } else {
            await Token.create({
                userId,
                platform: 'youtube',
                accessToken: tokens.access_token,
                refreshToken: tokens.refresh_token || '',
                platformAccountId: ytChannelId,
                platformAccountName: ytChannelName,
                profileAvatar: ytAvatar,
                extraData: { ytUploadsPlaylistId }
            });
        }

        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#FF0000; font-size:32px;">▶️ YouTube Linked!</h1>
                <p style="font-size:18px; color:#555;">Channel successfully connected.</p>
                <script>setTimeout(() => { window.location.href = "creatoros://auth/success"; setTimeout(() => window.close(), 1000); }, 1000);</script>
              </div>
            </body>
            </html>
        `);
    } catch (error) { res.status(500).json({ error: 'Failed to authenticate' }); }
};

exports.getChannelInfo = async (req, res) => {
    try {
        const userId = req.query.userId || DEFAULT_USER_ID;
        const youtube = await getYouTubeClient(userId);
        if (!youtube) return res.status(401).json({ error: 'Not connected' });
        const response = await youtube.channels.list({ part: 'snippet,contentDetails,statistics', mine: true });
        res.json(response.data);
    } catch (error) { res.status(500).json({ error: 'Failed' }); }
};

exports.getStatus = async (req, res) => {
    const userId = req.query.userId || DEFAULT_USER_ID;
    const tokenDoc = await Token.findOne({ userId, platform: 'youtube' });
    res.json({ 
        connected: !!tokenDoc,
        name: tokenDoc ? tokenDoc.platformAccountName : null,
        avatar: tokenDoc ? tokenDoc.profileAvatar : null,
        id: tokenDoc ? tokenDoc.platformAccountId : null
    });
};

exports.publishToYouTube = async (mediaPath, metadata, userId = DEFAULT_USER_ID) => {
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

exports.disconnect = async (req, res) => {
    const userId = req.query.userId || DEFAULT_USER_ID;
    await Token.deleteOne({ userId, platform: 'youtube' });
    res.json({ success: true, message: 'YouTube disconnected' });
};
