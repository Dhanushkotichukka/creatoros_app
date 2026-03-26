const axios = require('axios');
require('dotenv').config();

async function resolveIGAccount(accessToken) {
    try {
        const userRes = await axios.get(`https://graph.facebook.com/v19.0/me?fields=name,id&access_token=${accessToken}`);
        console.log(`[DIAGNOSTIC] Authenticated User: ${userRes.data.name} (ID: ${userRes.data.id})`);
        
        // Audit permissions
        const permRes = await axios.get(`https://graph.facebook.com/v19.0/me/permissions?access_token=${accessToken}`);
        const perms = permRes.data.data.filter(p => p.status === 'granted').map(p => p.permission);
        console.log(`[DIAGNOSTIC] GRANTED PERMISSIONS: ${perms.join(', ')}`);

        // Deep Probe Strategy
        console.log('[DIAGNOSTIC] Probing /me/accounts...');
        const accRes = await axios.get(`https://graph.facebook.com/v19.0/me/accounts?fields=instagram_business_account,name,tasks,category&access_token=${accessToken}`);
        console.log('[DIAGNOSTIC] /me/accounts RESPONSE:', JSON.stringify(accRes.data, null, 2));
        
        let pages = accRes.data.data || [];

        // If empty, try direct Page ID probe (from user's screenshot)
        if (pages.length === 0) {
            console.log('[DIAGNOSTIC] Attempting direct probe for Page: 966887149846053...');
            try {
                const directPage = await axios.get(`https://graph.facebook.com/v19.0/966887149846053?fields=instagram_business_account,name&access_token=${accessToken}`);
                console.log('[DIAGNOSTIC] DIRECT PAGE PROBE SUCCESS:', directPage.data.name);
                pages.push(directPage.data);
            } catch (e) {
                console.log('[DIAGNOSTIC] DIRECT PAGE PROBE FAILED:', e.response?.data || e.message);
            }
        }

        // Try Probing Businesses
        if (pages.length === 0) {
            console.log('[DIAGNOSTIC] Probing /me/businesses...');
            try {
                const bizRes = await axios.get(`https://graph.facebook.com/v19.0/me/businesses?access_token=${accessToken}`);
                console.log('[DIAGNOSTIC] /me/businesses RESPONSE:', JSON.stringify(bizRes.data, null, 2));
                const businesses = bizRes.data.data || [];
                for (const biz of businesses) {
                    const bizPages = await axios.get(`https://graph.facebook.com/v19.0/${biz.id}/owned_pages?fields=instagram_business_account,name&access_token=${accessToken}`);
                    console.log(`[DIAGNOSTIC] Biz ${biz.name} Pages:`, bizPages.data.data?.length || 0);
                    pages = pages.concat(bizPages.data.data || []);
                }
            } catch (e) {
                console.log('[DIAGNOSTIC] BUSINESS PROBE FAILED');
            }
        }

        console.log(`[DIAGNOSTIC] Total Resolved Pages: ${pages.length}`);

        for (const page of pages) {
            console.log(`[DIAGNOSTIC] Page: "${page.name}" (Cat: ${page.category}) - IG Account: ${page.instagram_business_account?.id || 'NONE'}`);
            if (page.instagram_business_account) {
                const igId = page.instagram_business_account.id;
                const igInfo = await axios.get(`https://graph.facebook.com/v19.0/${igId}?fields=username,name,profile_picture_url&access_token=${accessToken}`);
                global.igAccountId = igId;
                global.igUsername = igInfo.data.username;
                global.igName = igInfo.data.name;
                global.igAvatar = igInfo.data.profile_picture_url;
                console.log(`[DIAGNOSTIC] RESOLVED: @${global.igUsername}`);
                const { saveSessions } = require('../utils/sessionHelper');
                saveSessions();
                return true;
            }
        }

        if (pages.length > 0 && !pages.some(p => p.instagram_business_account)) {
            console.warn('[DIAGNOSTIC] Pages found, but NONE have a linked Instagram Business Account.');
        }

    } catch (err) {
        console.error('[DIAGNOSTIC] Deep Resolution Error:', err.response?.data?.error?.message || err.message);
    }
    return false;
}

const APP_ID = process.env.META_APP_ID;
const APP_SECRET = process.env.META_APP_SECRET;
const REDIRECT_URI = 'http://localhost:3000/auth/meta/callback';

exports.getLoginUrl = (req, res) => {
    const scopes = [
        'instagram_basic',
        'instagram_content_publish',
        'instagram_manage_comments',
        'instagram_manage_insights',
        'pages_show_list',
        'pages_read_engagement',
        'pages_manage_posts',
        'public_profile'
    ];
    const url = `https://www.facebook.com/v19.0/dialog/oauth?client_id=${APP_ID}&redirect_uri=${REDIRECT_URI}&scope=${scopes.join(',')}&response_type=code`;
    res.json({ url });
};

exports.handleCallback = async (req, res) => {
    const { code } = req.query;
    if (!code) return res.status(400).send('No code provided');

    try {
        // Exchange code for short-lived token
        const tokenResponse = await axios.get(`https://graph.facebook.com/v19.0/oauth/access_token?client_id=${APP_ID}&redirect_uri=${REDIRECT_URI}&client_secret=${APP_SECRET}&code=${code}`);
        const accessToken = tokenResponse.data.access_token;
        global.metaToken = accessToken;

        // Automatically resolve the linked Instagram Business Account
        await resolveIGAccount(accessToken);

        // In a real app, you'd exchange this for a long-lived token
        // and save it to a database. For now, we return it to the UI (or a success page).
        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#1877F2; font-size:32px;">📷 Meta Connected!</h1>
                <p style="font-size:18px; color:#555;">Your account is successfully linked.</p>
                <p style="color:#888;">Redirecting back to CreatorOS...</p>
                <a href="creatoros://auth/success" style="display:inline-block; margin-top:20px; padding:12px 24px; background:#1877F2; color:white; text-decoration:none; border-radius:8px; font-weight:bold;">Return to App</a>
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
        console.error('Meta Auth Error:', error.response?.data || error.message);
        res.status(500).send('Authentication failed');
    }
};

exports.getInstagramAnalytics = async (req, res) => {
    // Requires an Instagram Business Account linked to a Facebook Page
    // This expects the Page Access Token to be passed in Auth headers or query
    const { pageId, igAccountId } = req.query;
    const accessToken = req.headers.authorization?.split(' ')[1] || global.metaToken;

    if (!igAccountId || !accessToken) {
        return res.status(400).json({ error: 'Missing igAccountId or access token' });
    }

    try {
        // Fetch lifetime insights and daily metrics (reach, impressions, profile views)
        const response = await axios.get(`https://graph.facebook.com/v19.0/${igAccountId}/insights`, {
            params: {
                metric: 'impressions,reach,profile_views',
                period: 'day',
                access_token: accessToken
            }
        });

        // Fetch recent media (Reels/Posts) performance
        const mediaResponse = await axios.get(`https://graph.facebook.com/v19.0/${igAccountId}/media`, {
            params: {
                fields: 'id,caption,media_type,media_url,thumbnail_url,like_count,comments_count,timestamp,insights.metric(impressions,reach,engagement)',
                access_token: accessToken,
                limit: 10
            }
        });

        res.json({
            platform: 'Instagram',
            dailyInsights: response.data.data,
            recentMedia: mediaResponse.data.data
        });

    } catch (error) {
        console.error('IG Analytics Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to fetch Instagram analytics' });
    }
};

exports.getFacebookAnalytics = async (req, res) => {
    const { pageId } = req.query;
    const accessToken = req.headers.authorization?.split(' ')[1] || global.metaToken;

    if (!pageId || !accessToken) {
        return res.status(400).json({ error: 'Missing pageId or access token' });
    }

    try {
        const response = await axios.get(`https://graph.facebook.com/v19.0/${pageId}/insights`, {
            params: {
                metric: 'page_impressions_unique,page_engaged_users,page_post_engagements',
                period: 'day',
                access_token: accessToken
            }
        });

        res.json({
            platform: 'Facebook',
            pageInsights: response.data.data
        });

    } catch (error) {
        console.error('FB Analytics Error:', error.response?.data || error.message);
        res.status(500).json({ error: 'Failed to fetch Facebook analytics' });
    }
};

exports.getStatus = async (req, res) => {
    if (global.metaToken && !global.igAccountId) {
        await resolveIGAccount(global.metaToken);
    }
    res.json({ 
        connected: !!global.metaToken,
        username: global.igUsername,
        name: global.igName,
        avatar: global.igAvatar
    });
};

exports.resolveIGAccount = resolveIGAccount;

exports.disconnect = (req, res) => {
    global.metaToken = null;
    global.igAccountId = null;
    global.igUsername = null;
    global.igName = null;
    global.igAvatar = null;
    const { saveSessions } = require('../utils/sessionHelper');
    saveSessions();
    res.json({ success: true, message: 'Meta disconnected' });
};
