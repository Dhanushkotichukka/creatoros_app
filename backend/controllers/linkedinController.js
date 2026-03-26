const axios = require('axios');
require('dotenv').config();

const CLIENT_ID = process.env.LINKEDIN_CLIENT_ID;
const CLIENT_SECRET = process.env.LINKEDIN_CLIENT_SECRET;
const REDIRECT_URI = 'http://localhost:3000/auth/linkedin/callback';

exports.getLoginUrl = (req, res) => {
    const scopes = ['w_member_social', 'openid', 'profile', 'email'];
    const url = `https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${scopes.join('%20')}`;
    res.json({ url });
};

exports.handleCallback = async (req, res) => {
    const { code } = req.query;
    if (!code) return res.status(400).send('No code provided');

    try {
        const tokenResponse = await axios.post('https://www.linkedin.com/oauth/v2/accessToken', 
            new URLSearchParams({
                grant_type: 'authorization_code',
                code: code,
                redirect_uri: REDIRECT_URI,
                client_id: CLIENT_ID,
                client_secret: CLIENT_SECRET
            }).toString(),
            { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
        );

        const accessToken = tokenResponse.data.access_token;
        global.linkedinToken = accessToken;

        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#0077B5; font-size:32px;">💼 LinkedIn Linked!</h1>
                <p style="font-size:18px; color:#555;">Your professional profile is connected.</p>
                <p style="color:#888;">Redirecting back to CreatorOS...</p>
                <a href="creatoros://auth/success" style="display:inline-block; margin-top:20px; padding:12px 24px; background:#0077B5; color:white; text-decoration:none; border-radius:8px; font-weight:bold;">Return to App</a>
                <script>
                  setTimeout(() => {
                    window.location.href = "creatoros://auth/success";
                    setTimeout(() => window.close(), 1000);
                  }, 1000);
                </script>
              </div>
            </body>
            </html>
        `);
    } catch (error) {
        console.error('LinkedIn Auth Error:', error.response?.data || error.message);
        res.status(500).send('Authentication failed');
    }
};

exports.getLinkedInAnalytics = async (req, res) => {
    // Requires the organization URN and a valid access token with rw_organization_admin scopes
    const { organizationUrn } = req.query;
    const accessToken = req.headers.authorization?.split(' ')[1] || global.linkedinToken;

    if (!organizationUrn || !accessToken) {
        return res.status(400).json({ error: 'Missing organizationUrn or access token' });
    }

    try {
        // Fetch Organization Page Statistics (followers, page views)
        const pageStatsResponse = await axios.get(`https://api.linkedin.com/rest/organizationalEntityFollowerStatistics?q=organizationalEntity&organizationalEntity=${encodeURIComponent(organizationUrn)}`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'LinkedIn-Version': '202401' // Use latest version header
            }
        });

        // Fetch Share/Post Statistics (clicks, likes, comments, impressions)
        const shareStatsResponse = await axios.get(`https://api.linkedin.com/rest/organizationalEntityShareStatistics?q=organizationalEntity&organizationalEntity=${encodeURIComponent(organizationUrn)}`, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'LinkedIn-Version': '202401'
            }
        });

        res.json({
            platform: 'LinkedIn',
            followerStats: pageStatsResponse.data,
            engagementStats: shareStatsResponse.data
        });

    } catch (error) {
        console.error('LinkedIn Analytics Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to fetch LinkedIn analytics' });
    }
};

exports.getStatus = (req, res) => {
    res.json({ connected: !!global.linkedinToken });
};

exports.disconnect = (req, res) => {
    global.linkedinToken = null;
    res.json({ success: true, message: 'LinkedIn disconnected' });
};
