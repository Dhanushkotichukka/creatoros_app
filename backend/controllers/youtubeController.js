const { google } = require('googleapis');
require('dotenv').config();

const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    'http://localhost:3000/auth/youtube/callback'
);

// ONE-TIME LISTENER setup to avoid memory leaks
oauth2Client.on('tokens', (tokens) => {
    console.log('[AUTH] New YouTube tokens received.');
    if (tokens.refresh_token) global.youtubeRefreshToken = tokens.refresh_token;
    if (tokens.access_token) global.youtubeToken = tokens.access_token;
    
    try {
        const { saveSessions } = require('../utils/sessionHelper');
        saveSessions();
    } catch (e) { console.error('[AUTH] Failed to save refreshed session:', e.message); }
});

async function getYouTubeClient() {
    if (!global.youtubeToken) return null;
    oauth2Client.setCredentials({
        access_token: global.youtubeToken,
        refresh_token: global.youtubeRefreshToken
    });
    return google.youtube({ version: 'v3', auth: oauth2Client });
}

async function getYouTubeAnalyticsClient() {
    if (!global.youtubeToken) return null;
    oauth2Client.setCredentials({
        access_token: global.youtubeToken,
        refresh_token: global.youtubeRefreshToken
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
        global.youtubeToken = tokens.access_token;
        global.youtubeRefreshToken = tokens.refresh_token || global.youtubeRefreshToken;
        oauth2Client.setCredentials(tokens);

        try {
            const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
            const ytResponse = await youtube.channels.list({ part: 'snippet,contentDetails', mine: true });
            if (ytResponse.data.items?.length) {
                const channel = ytResponse.data.items[0];
                global.ytChannelId = channel.id; // SAVE CHANNEL ID
                global.ytChannelName = channel.snippet.title;
                global.ytAvatar = channel.snippet.thumbnails.default.url;
                global.ytUploadsPlaylistId = channel.contentDetails.relatedPlaylists.uploads; // SAVE UPLOADS ID
            }
        } catch (e) { 
            console.warn('[YT] Profile API quota hit. Falling back to Google Profile for avatar:', e.message); 
            try {
                const oauth2 = google.oauth2({ auth: oauth2Client, version: 'v2' });
                const userInfo = await oauth2.userinfo.get();
                global.ytChannelName = userInfo.data.name || 'Connected Creator';
                global.ytAvatar = userInfo.data.picture;
            } catch (err) {
                console.error('[YT] Both Profile and UserInfo failed:', err.message);
            }
        }

        const { saveSessions } = require('../utils/sessionHelper');
        saveSessions();

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
        const youtube = await getYouTubeClient();
        if (!youtube) return res.status(401).json({ error: 'Not connected' });
        const response = await youtube.channels.list({ part: 'snippet,contentDetails,statistics', mine: true });
        res.json(response.data);
    } catch (error) { res.status(500).json({ error: 'Failed' }); }
};

exports.getStatus = (req, res) => {
    res.json({ 
        connected: !!global.youtubeToken,
        name: global.ytChannelName,
        avatar: global.ytAvatar,
        id: global.ytChannelId // EXPOSE ID
    });
};

exports.publishToYouTube = async (mediaPath, metadata) => {
    const youtube = await getYouTubeClient();
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

exports.disconnect = (req, res) => {
    global.youtubeToken = null;
    global.youtubeRefreshToken = null;
    global.ytChannelName = null;
    global.ytAvatar = null;
    global.ytChannelId = null;
    global.ytUploadsPlaylistId = null;
    const { saveSessions } = require('../utils/sessionHelper');
    saveSessions();
    res.json({ success: true, message: 'YouTube disconnected' });
};
