const axios = require('axios');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function resolveIGAccount(accessToken) {
    try {
        const userRes = await axios.get(`https://graph.facebook.com/v19.0/me?fields=name,id&access_token=${accessToken}`);
        console.log(`[DIAGNOSTIC] Authenticated User: ${userRes.data.name} (ID: ${userRes.data.id})`);
        
        const debugPath = path.join(__dirname, '../utils/meta_debug.json');
        let debugData = { 
            user: userRes.data,
            timestamp: new Date().toISOString(),
            permissions: [],
            rawPages: [],
            igAccounts: []
        };

        // Audit permissions
        const permRes = await axios.get(`https://graph.facebook.com/v19.0/me/permissions?access_token=${accessToken}`);
        debugData.permissions = permRes.data.data;
        const perms = permRes.data.data.filter(p => p.status === 'granted').map(p => p.permission);
        console.log(`[DIAGNOSTIC] GRANTED PERMISSIONS: ${perms.join(', ')}`);

        // Deep Probe Strategy
        console.log('[DIAGNOSTIC] Probing /me/accounts...');
        const accRes = await axios.get(`https://graph.facebook.com/v19.0/me/accounts?fields=instagram_business_account,name,tasks,category&access_token=${accessToken}`);
        debugData.rawPages = accRes.data.data || [];
        console.log('[DIAGNOSTIC] /me/accounts RESPONSE:', JSON.stringify(accRes.data, null, 2));
        
        let pages = accRes.data.data || [];

        // NOTE: DO NOT add any hardcoded page ID fallbacks here.
        // The pages list is controlled entirely by what the user selects
        // in the Facebook OAuth dialog. Only selected pages appear here.

        // Try Probing Businesses (only if no pages at all)
        if (pages.length === 0) {
            console.log('[DIAGNOSTIC] Probing /me/businesses...');
            try {
                const bizRes = await axios.get(`https://graph.facebook.com/v19.0/me/businesses?access_token=${accessToken}`);
                console.log('[DIAGNOSTIC] /me/businesses RESPONSE:', JSON.stringify(bizRes.data, null, 2));
                const businesses = bizRes.data.data || [];
                debugData.businesses = businesses; // Capture businesses in debug
                for (const biz of businesses) {
                    const bizPages = await axios.get(`https://graph.facebook.com/v19.0/${biz.id}/owned_pages?fields=instagram_business_account,name&access_token=${accessToken}`);
                    pages = pages.concat(bizPages.data.data || []);
                }
            } catch (e) {
                console.log('[DIAGNOSTIC] BUSINESS PROBE FAILED');
            }
        }

        // Direct Instagram Account Probe (New Strategy)
        if (pages.length === 0 || !pages.some(p => p.instagram_business_account)) {
            console.log('[DIAGNOSTIC] Attempting Direct Instagram Account Probe...');
            try {
                const igAccRes = await axios.get(`https://graph.facebook.com/v19.0/me?fields=instagram_accounts{id,username,name,profile_picture_url},instagram_business_account{id,username,name,profile_picture_url}&access_token=${accessToken}`);
                const igAccounts = igAccRes.data.instagram_accounts?.data || [];
                
                // Also check the singular business account field directly on the user
                if (igAccRes.data.instagram_business_account) {
                    igAccounts.push(igAccRes.data.instagram_business_account);
                }

                debugData.igAccounts = igAccounts; 
                console.log(`[DIAGNOSTIC] Direct IG Accounts Found: ${igAccounts.length}`);
                
                for (const igAcc of igAccounts) {
                    pages.push({
                        name: igAcc.name || igAcc.username,
                        instagram_business_account: { id: igAcc.id },
                        category: 'DIRECT_IG'
                    });
                }
            } catch (e) {
                console.log('[DIAGNOSTIC] DIRECT IG PROBE FAILED:', e.response?.data || e.message);
            }
        }

        // Nested Accounts Probe (The "God-Probe")
        if (pages.length === 0 || !pages.some(p => p.instagram_business_account)) {
            console.log('[DIAGNOSTIC] Attempting Nested Accounts Probe...');
            try {
                const nestedRes = await axios.get(`https://graph.facebook.com/v19.0/me?fields=accounts{instagram_business_account{id,username,name,profile_picture_url},name}&access_token=${accessToken}`);
                const nestedPages = nestedRes.data.accounts?.data || [];
                debugData.nestedPages = nestedPages; 
                console.log(`[DIAGNOSTIC] Nested Pages Found: ${nestedPages.length}`);

                for (const np of nestedPages) {
                    if (np.instagram_business_account) {
                        pages.push(np);
                    }
                }
            } catch (e) {
                console.log('[DIAGNOSTIC] NESTED PROBE FAILED:', e.response?.data || e.message);
            }
        }

        console.log(`[DIAGNOSTIC] Total Resolved Pages: ${pages.length}`);

        // Collect ALL pages that have an instagram_business_account linked.
        // This respects exactly which page the user selected in the OAuth dialog.
        const igPages = [];
        for (const page of pages) {
            console.log(`[DIAGNOSTIC] Page: "${page.name}" (Cat: ${page.category}) - IG Account: ${page.instagram_business_account?.id || 'NONE'}`);
            if (page.instagram_business_account) {
                igPages.push({ page, igId: page.instagram_business_account.id });
            }
        }

        if (igPages.length === 0) {
            console.warn('[DIAGNOSTIC] No pages with a linked Instagram Business Account found.');
            // Save debug data if failed
            fs.writeFileSync(debugPath, JSON.stringify(debugData, null, 2));
        } else {
            // ... rest of the logic ...
            const { page: selectedPage, igId } = igPages[0];
            debugData.selectedIgId = igId;
            console.log(`[DIAGNOSTIC] Using IG from page: "${selectedPage.name}" (IG ID: ${igId})`);
            const igInfo = await axios.get(`https://graph.facebook.com/v19.0/${igId}?fields=username,name,profile_picture_url&access_token=${accessToken}`);
            global.igAccountId = igId;
            global.igUsername = igInfo.data.username;
            global.igName = igInfo.data.name;
            global.igAvatar = igInfo.data.profile_picture_url;
            console.log(`[DIAGNOSTIC] RESOLVED: @${global.igUsername}`);
            
            // Save successful debug data too
            debugData.resolvedIg = igInfo.data;
            fs.writeFileSync(debugPath, JSON.stringify(debugData, null, 2));

            const { saveSessions } = require('../utils/sessionHelper');
            saveSessions();
            return true;
        }

        if (pages.length > 0 && !pages.some(p => p.instagram_business_account)) {
            console.warn('[DIAGNOSTIC] Pages found, but NONE have a linked Instagram Business Account.');
        }

    } catch (err) {
        console.error('[DIAGNOSTIC] Deep Resolution Error:', err.response?.data?.error?.message || err.message);
        try {
            fs.writeFileSync(path.join(__dirname, '../utils/meta_debug_error.json'), JSON.stringify(err.response?.data || {message: err.message}, null, 2));
        } catch(e) {}
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
        'public_profile',
        'business_management'
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

const pollStatus = async (igAccountId, creationId, accessToken) => {
    let attempts = 0;
    const maxAttempts = 30; // 5 minutes max
    const statusLogPath = path.join(__dirname, '../utils/publish_status.txt');
    fs.writeFileSync(statusLogPath, `[INSTAGRAM] Started polling for container: ${creationId}\n`);

    while (attempts < maxAttempts) {
        try {
            const response = await axios.get(`https://graph.facebook.com/v19.0/${creationId}`, {
                params: {
                    fields: 'status_code,status,video_status',
                    access_token: accessToken
                }
            });
            const status = response.data.status_code;
            const logMsg = `[${new Date().toLocaleTimeString()}] Attempt ${attempts + 1}: ${status}\n`;
            fs.appendFileSync(statusLogPath, logMsg);
            
            console.log(`[INSTAGRAM] Container ${creationId} full status:`, JSON.stringify(response.data, null, 2));
            if (status === 'FINISHED') {
                fs.appendFileSync(statusLogPath, `[INSTAGRAM] SUCCESS: Ready to publish!\n`);
                return true;
            }
            if (status === 'ERROR') {
                const msg = response.data.video_status?.error_description || 'Meta processing failed';
                throw new Error(`Instagram Processing Error: ${msg}`);
            }
        } catch (e) {
            console.error(`[INSTAGRAM] Polling error during attempt ${attempts + 1}:`, e.message);
            fs.appendFileSync(statusLogPath, `[${new Date().toLocaleTimeString()}] Polling Error: ${e.message}\n`);
            // Only throw if it's a definitive "ERROR" from Meta, otherwise retry
            if (e.message && e.message.includes('Instagram Processing Error')) throw e;
        }
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10s
        attempts++;
    }
    throw new Error('Video processing timed out on Meta side');
};

exports.publishToInstagram = async (mediaUrl, metadata) => {
    if (!global.metaToken || !global.igAccountId) throw new Error('Instagram not connected');
    
    // Warn if local URL is used
    if (mediaUrl.includes('localhost') || mediaUrl.includes('127.0.0.1')) {
        console.warn('[INSTAGRAM] WARNING: Using a local media URL. Meta servers will NOT be able to download this file!');
    }

    // Deep Detection: S3 presigned URLs have params after the extension, so endsWith fails.
    // We check if the path part of the URL contains .mp4 or .mov
    const isVideo = mediaUrl.toLowerCase().split('?')[0].endsWith('.mp4') || 
                    mediaUrl.toLowerCase().split('?')[0].endsWith('.mov') ||
                    mediaUrl.toLowerCase().includes('.mp4?') ||
                    mediaUrl.toLowerCase().includes('.mov?');
    
    console.log(`[INSTAGRAM] Detected media format for: ${mediaUrl.split('?')[0]} -> ${isVideo ? 'VIDEO' : 'IMAGE'}`);
    console.log(`[INSTAGRAM] Publishing ${isVideo ? 'VIDEO' : 'IMAGE'} to Instagram...`);

    try {
        // Step 1: Create Media Container
        // PREPARE UNIFIED CAPTION
        const titlePart = metadata.title ? `${metadata.title.toUpperCase()}\n\n` : '';
        const descPart = metadata.description ? `${metadata.description}\n\n` : '';
        const hashtagsPart = (metadata.hashtags && metadata.hashtags.length > 0) 
            ? metadata.hashtags.map(tag => tag.startsWith('#') ? tag : `#${tag}`).join(' ') 
            : '';
        
        const unifiedCaption = `${titlePart}${descPart}${hashtagsPart}`.trim();

        const containerParams = {
            caption: unifiedCaption,
            access_token: global.metaToken,
            share_to_feed: true // Ensure it shows up on the main grid
        };

        // ENCODE the URL to prevent S3 special characters from breaking the Meta API call
        const encodedMediaUrl = encodeURIComponent(mediaUrl);

        // Use the ENCODED URL for Meta
        if (isVideo) {
            containerParams.video_url = mediaUrl; // Axios params object handles the encoding of components
            containerParams.media_type = 'REELS';
        } else {
            containerParams.image_url = mediaUrl;
        }

        console.log(`[INSTAGRAM] Creating container for ${isVideo ? 'VIDEO' : 'IMAGE'}...`);
        const containerRes = await axios.post(`https://graph.facebook.com/v19.0/${global.igAccountId}/media`, null, {
            params: containerParams
        });
        
        const creationId = containerRes.data?.id;
        if (!creationId) throw new Error('Meta did not return a media creation ID');
        
        // Step 2: For Videos, wait for processing to finish
        if (isVideo) {
            console.log(`[INSTAGRAM] Waiting for video processing: ${creationId}`);
            await pollStatus(global.igAccountId, creationId, global.metaToken);
        }
        
        // Step 3: Publish Media
        const publishRes = await axios.post(`https://graph.facebook.com/v19.0/${global.igAccountId}/media_publish`, null, {
            params: {
                creation_id: creationId,
                access_token: global.metaToken
            }
        });
        
        return { success: true, platform: 'Instagram', id: publishRes.data.id };
    } catch (error) {
        const metaError = error.response?.data?.error?.message || error.message;
        const metaDetail = error.response?.data?.error?.error_user_msg || '';
        console.error('Instagram Publish Error:', metaError, metaDetail);
        throw new Error(`Instagram Error: ${metaError} ${metaDetail}`);
    }
};

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
