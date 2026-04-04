const { google } = require('googleapis');
require('dotenv').config();

const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    'http://localhost:3000/auth/youtube/callback'
);

exports.getAuthUrl = (req, res) => {
    const scopes = [
        'https://www.googleapis.com/auth/youtube.readonly',
        'https://www.googleapis.com/auth/youtube.upload',
        'https://www.googleapis.com/auth/yt-analytics.readonly',
        'https://www.googleapis.com/auth/yt-analytics-monetary.readonly',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/userinfo.email'
    ];

    const url = oauth2Client.generateAuthUrl({
        access_type: 'offline',
        scope: scopes,
        prompt: 'consent'
    });

    res.redirect(url);
};

exports.handleCallback = async (req, res) => {
    const { code } = req.query;
    try {
        const { tokens } = await oauth2Client.getToken(code);
        oauth2Client.setCredentials(tokens);
        
        global.youtubeToken = tokens.access_token;

        // Fetch channel info immediately to store profile data
        try {
            const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
            const ytResponse = await youtube.channels.list({
                part: 'snippet',
                mine: true
            });
            if (ytResponse.data.items && ytResponse.data.items.length > 0) {
                const channel = ytResponse.data.items[0];
                global.ytChannelName = channel.snippet.title;
                global.ytAvatar = channel.snippet.thumbnails.default.url;
            }
        } catch (ytInfoError) {
            console.error('Error fetching YT profile:', ytInfoError.message);
        }

        const { saveSessions } = require('../utils/sessionHelper');
        saveSessions();

        // In a real app, you'd save these to a database linked to the user
        console.log('Successfully authenticated with YouTube');

        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#FF0000; font-size:32px;">▶️ YouTube Linked!</h1>
                <p style="font-size:18px; color:#555;">Your channel is successfully connected.</p>
                <p style="color:#888;">Redirecting you back to the app...</p>
                <a href="creatoros://auth/success" style="display:inline-block; margin-top:20px; padding:12px 24px; background:#FF0000; color:white; text-decoration:none; border-radius:8px; font-weight:bold;">Return to CreatorOS</a>
                <script>
                  // Attempt to auto-redirect
                  setTimeout(() => {
                    window.location.href = "creatoros://auth/success";
                    // Fallback close
                    setTimeout(() => window.close(), 1000);
                  }, 1000);
                </script>
              </div>
            </body>
            </html>
        `);
    } catch (error) {
        console.error('Error authenticating with YouTube:', error);
        res.status(500).json({ error: 'Failed to authenticate with YouTube' });
    }
};

exports.getChannelInfo = async (req, res) => {
    // This assumes tokens are already set or passed in
    try {
        const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
        const response = await youtube.channels.list({
            part: 'snippet,contentDetails,statistics',
            mine: true
        });

        res.json(response.data);
    } catch (error) {
        console.error('Error fetching channel info:', error);
        res.status(500).json({ error: 'Failed to fetch channel info' });
    }
};

exports.getAnalytics = async (req, res) => {
    try {
        const youtubeAnalytics = google.youtubeAnalytics({ version: 'v2', auth: oauth2Client });
        // Example: Get basic views and watch time for the last 30 days
        const endDate = new Date().toISOString().split('T')[0];
        const startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

        const response = await youtubeAnalytics.reports.query({
            ids: 'channel==MINE',
            startDate: startDate,
            endDate: endDate,
            metrics: 'views,estimatedMinutesWatched,averageViewDuration,averageViewPercentage,subscribersGained,likes,comments',
            dimensions: 'day',
            sort: 'day'
        });

        // Format the graph data response
        const rows = response.data.rows || [];
        const graphData = {
            dates: rows.map(r => r[0]),
            views: rows.map(r => r[1]),
            watchTime: rows.map(r => r[2]),
            retention: rows.map(r => r[4]), // averageViewPercentage
            likes: rows.map(r => r[6]),
        };

        // Combine into unified format
        const totalViews = rows.reduce((sum, r) => sum + r[1], 0);

        res.json({
            platform: 'YouTube',
            timeRange: '30 Days',
            totals: {
                totalViews,
            },
            graphData
        });

    } catch (error) {
        console.error('Error fetching YouTube analytics:', error);
        res.status(500).json({ error: 'Failed to fetch YouTube analytics' });
    }
};

exports.getVideoDeepAnalytics = async (req, res) => {
    const { videoId } = req.params;
    try {
        const youtubeAnalytics = google.youtubeAnalytics({ version: 'v2', auth: oauth2Client });
        const endDate = new Date().toISOString().split('T')[0];
        const startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

        // Fetch Audience locations and Age Groups
        const demoResponse = await youtubeAnalytics.reports.query({
            ids: 'channel==MINE',
            startDate: startDate,
            endDate: endDate,
            metrics: 'viewerPercentage',
            dimensions: 'ageGroup,gender',
            filters: `video==${videoId}`
        });

        // Fetch Traffic Sources
        const trafficResponse = await youtubeAnalytics.reports.query({
            ids: 'channel==MINE',
            startDate: startDate,
            endDate: endDate,
            metrics: 'views',
            dimensions: 'insightTrafficSourceType',
            filters: `video==${videoId}`
        });

        res.json({
            videoId,
            demographics: demoResponse.data,
            trafficSources: trafficResponse.data
        });

    } catch (error) {
        console.error('Error fetching deep video analytics:', error);
        res.status(500).json({ error: 'Failed to fetch deep video analytics' });
    }
};

exports.getStatus = (req, res) => {
    res.json({ 
        connected: !!global.youtubeToken,
        name: global.ytChannelName,
        avatar: global.ytAvatar
    });
};

exports.publishToYouTube = async (mediaPath, metadata) => {
    if (!global.youtubeToken) throw new Error('YouTube not connected');
    
    // Ensure the OAuth client is re-synced with the global token (Crucial after server restart)
    oauth2Client.setCredentials({ access_token: global.youtubeToken });
    
    const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
    const fs = require('fs');
    
    try {
        const response = await youtube.videos.insert({
            part: 'snippet,status',
            requestBody: {
                snippet: {
                    title: metadata.title || 'New Video from CreatorOS',
                    description: `${metadata.description || ''}\n\n${(metadata.hashtags || []).map(tag => tag.startsWith('#') ? tag : `#${tag}`).join(' ')}`.trim(),
                    tags: (metadata.hashtags || []).map(tag => tag.replace('#', '')),
                },
                status: {
                    privacyStatus: metadata.privacyStatus || 'public', // Set dynamically based on chosen privacy status flag
                    madeForKids: metadata.madeForKids || false, // COPPA compliance
                },
            },
            media: {
                body: fs.createReadStream(mediaPath),
            },
        });
        return { success: true, platform: 'YouTube', id: response.data.id };
    } catch (error) {
        console.error('YouTube Publish Error:', error.response?.data || error.message);
        throw error;
    }
};

exports.disconnect = (req, res) => {
    global.youtubeToken = null;
    global.ytChannelName = null;
    global.ytAvatar = null;
    const { saveSessions } = require('../utils/sessionHelper');
    saveSessions();
    res.json({ success: true, message: 'YouTube disconnected' });
};
