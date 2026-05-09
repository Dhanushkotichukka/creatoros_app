const axios = require('axios');
const fs = require('fs');
const path = require('path');
const Token = require('../models/Token');
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

            const DEFAULT_USER_ID = 'default-user-id';
            let tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'meta' });
            if (!tokenDoc) {
                 tokenDoc = new Token({ userId: DEFAULT_USER_ID, platform: 'meta', accessToken });
            }
            tokenDoc.platformAccountId = igId;
            tokenDoc.extraData = { igUsername: igInfo.data.username };
            tokenDoc.platformAccountName = igInfo.data.name;
            tokenDoc.profileAvatar = igInfo.data.profile_picture_url;
            await tokenDoc.save();

            console.log(`[DIAGNOSTIC] RESOLVED: @${tokenDoc.extraData.igUsername}`);
            
            // Save successful debug data too
            debugData.resolvedIg = igInfo.data;
            fs.writeFileSync(debugPath, JSON.stringify(debugData, null, 2));

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

        const DEFAULT_USER_ID = 'default-user-id';
        let tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'meta' });
        if (!tokenDoc) {
             tokenDoc = new Token({ userId: DEFAULT_USER_ID, platform: 'meta', accessToken });
        } else {
             tokenDoc.accessToken = accessToken;
        }
        await tokenDoc.save();

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
    const DEFAULT_USER_ID = 'default-user-id';
    const tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'meta' });
    const accessToken = req.headers.authorization?.split(' ')[1] || tokenDoc?.accessToken;

    if (!igAccountId || !accessToken) {
        return res.status(400).json({ error: 'Missing igAccountId or access token' });
    }

    try {
        // Fetch lifetime insights and daily metrics (reach, impressions, profile views)
        const response = await axios.get(`https://graph.facebook.com/v19.0/${igAccountId}/insights`, {
            params: {
                metric: 'impressions,reach,profile_views',
                period: 'day',
                metric_type: 'total_value',
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
    const DEFAULT_USER_ID = 'default-user-id';
    const tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'meta' });
    const accessToken = req.headers.authorization?.split(' ')[1] || tokenDoc?.accessToken;

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
    const DEFAULT_USER_ID = 'default-user-id';
    const tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'meta' });
    if (tokenDoc?.accessToken && !tokenDoc?.platformAccountId) {
        await resolveIGAccount(tokenDoc?.accessToken);
    }
    res.json({ 
        connected: !!tokenDoc?.accessToken,
        username: tokenDoc?.extraData?.igUsername,
        name: tokenDoc?.platformAccountName,
        avatar: tokenDoc?.profileAvatar
    });
};

exports.resolveIGAccount = resolveIGAccount;

const pollStatus = async (igAccountId, creationId, accessToken, isVideo = false) => {
    let attempts = 0;
    const maxAttempts = 30; // 5 minutes max
    const statusLogPath = path.join(__dirname, '../utils/publish_status.txt');
    fs.writeFileSync(statusLogPath, `[INSTAGRAM] Started polling for container: ${creationId} (isVideo: ${isVideo})\n`);

    while (attempts < maxAttempts) {
        try {
            // Fields depends on whether it is a video (Reel/Video) or an Image/Carousel
            const fields = isVideo ? 'status_code,video_status' : 'status_code';
            const response = await axios.get(`https://graph.facebook.com/v19.0/${creationId}`, {
                params: { fields, access_token: accessToken }
            });
            const status = response.data.status_code;
            const logMsg = `[${new Date().toLocaleTimeString()}] Attempt ${attempts + 1}: ${status}\n`;
            fs.appendFileSync(statusLogPath, logMsg);
            
            console.log(`[INSTAGRAM] Container ${creationId} status:`, status);
            if (status === 'FINISHED') {
                fs.appendFileSync(statusLogPath, `[INSTAGRAM] SUCCESS: Ready to publish!\n`);
                return true;
            }
            if (status === 'ERROR') {
                const msg = response.data.video_status?.error_description || response.data.status || 'Meta processing failed';
                throw new Error(`Instagram Processing Error: ${msg}`);
            }
        } catch (e) {
            // If we get an error, log it. For carousels, item containers
            // must be FINISHED before we can create the parent container.
            const statusMsg = e.response?.data?.error?.message || e.message;
            console.warn(`[INSTAGRAM] Polling warning (attempt ${attempts + 1}):`, statusMsg);
            
            fs.appendFileSync(statusLogPath, `[${new Date().toLocaleTimeString()}] Polling Warning: ${statusMsg}\n`);
            if (statusMsg.includes('Instagram Processing Error')) throw e;
        }
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10s
        attempts++;
    }
    throw new Error('Video processing timed out on Meta side');
};

exports.publishToInstagram = async (mediaUrls, metadata, userId = 'default-user-id') => {
    const tokenDoc = await Token.findOne({ userId, platform: 'meta' });
    if (!tokenDoc?.accessToken || !tokenDoc?.platformAccountId) throw new Error('Instagram not connected');
    
    // Convert to array if it is a single string (backwards compatibility)
    const urls = Array.isArray(mediaUrls) ? mediaUrls : [mediaUrls];
    if (urls.length === 0) throw new Error('No media URLs provided');

    const isVideo = (url) => {
        const path = url.toLowerCase().split('?')[0];
        const ext = path.split('.').pop();
        return ['mp4', 'mov', 'avi', 'webm', 'mkv', 'wmv'].includes(ext) || path.includes('.mp4?') || path.includes('.mov?');
    }

    const postType = (metadata.contentType || 'Post').toUpperCase(); // POST, STORY, REEL
    console.log(`[INSTAGRAM] Detected media as ${urls.map(u => isVideo(u) ? 'VIDEO' : 'IMAGE').join(', ')}`);
    console.log(`[INSTAGRAM] Publishing ${urls.length} item(s) to Instagram as ${postType}...`);

    try {
        const accessToken = tokenDoc?.accessToken;
        const igId = tokenDoc?.platformAccountId;

        // PREPARE CAPTION (Stories don't support captions via API)
        const titlePart = metadata.title ? `${metadata.title.toUpperCase()}\n\n` : '';
        const descPart = metadata.description ? `${metadata.description}\n\n` : '';
        const hashtagsPart = (metadata.hashtags && metadata.hashtags.length > 0) 
            ? metadata.hashtags.map(tag => tag.startsWith('#') ? tag : `#${tag}`).join(' ') 
            : '';
        const unifiedCaption = (postType === 'STORY') ? '' : `${titlePart}${descPart}${hashtagsPart}`.trim();

        // ────── CASE 1: STORY (Single Media Only) ──────
        if (postType === 'STORY') {
            const url = urls[0];
            const isVid = isVideo(url);
            const params = {
                media_type: 'STORIES',
                access_token: accessToken
            };
            if (isVid) params.video_url = url; else params.image_url = url;

            const res = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params });
            const creationId = res.data.id;
            
            // ALWAYS poll for stories (video or image) to prevent "not ready" errors
            await pollStatus(igId, creationId, accessToken);

            const publishRes = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media_publish`, null, {
                params: { creation_id: creationId, access_token: accessToken }
            });
            return { success: true, platform: 'Instagram', id: publishRes.data.id, postType: 'STORY' };
        }

        // ────── CASE 2: CAROUSEL (Multiple Media) ──────
        if (urls.length > 1) {
            console.log(`[INSTAGRAM] Creating Carousel with ${urls.length} items...`);
            const itemContainerIds = [];

            for (const url of urls) {
                const isVid = isVideo(url);
                const itemParams = {
                    is_carousel_item: true,
                    access_token: accessToken
                };
                if (isVid) {
                    itemParams.video_url = url;
                    itemParams.media_type = 'VIDEO';
                } else {
                    itemParams.image_url = url;
                }

                const itemRes = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params: itemParams });
                itemContainerIds.push(itemRes.data.id);
            }

            // Wait for items to be processed (MANDATORY for all items, images and videos)
            for (let i = 0; i < itemContainerIds.length; i++) {
                const cId = itemContainerIds[i];
                const isVid = isVideo(urls[i]);
                console.log(`[INSTAGRAM] Verifying carousel item ${i+1}/${itemContainerIds.length}: ${cId} (${isVid ? 'VIDEO' : 'IMAGE'})`);
                await pollStatus(igId, cId, accessToken, isVid);
            }

            // Create Carousel Container
            console.log(`[INSTAGRAM] Creating Carousel Container...`);
            const carouselRes = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, {
                params: {
                    media_type: 'CAROUSEL',
                    children: itemContainerIds.join(','),
                    caption: unifiedCaption,
                    access_token: accessToken
                }
            });

            const creationId = carouselRes.data.id;
            // Carousels take time to process too
            console.log(`[INSTAGRAM] Waiting for Carousel Container to be ready...`);
            await pollStatus(igId, creationId, accessToken, false);

            console.log(`[INSTAGRAM] Publishing Carousel...`);
            await new Promise(r => setTimeout(r, 2000));
            
            try {
                const publishRes = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media_publish`, null, {
                    params: { creation_id: creationId, access_token: accessToken }
                });
                return { success: true, platform: 'Instagram', id: publishRes.data.id, postType: 'CAROUSEL' };
            } catch (publishErr) {
                const msg = publishErr.response?.data?.error?.message || publishErr.message;
                if (msg.includes('ready') || msg.includes('available')) {
                    console.log(`[INSTAGRAM] Carousel not quite ready (propagation delay). Retrying once in 5s...`);
                    await new Promise(r => setTimeout(r, 5000));
                    const retryRes = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media_publish`, null, {
                        params: { creation_id: creationId, access_token: accessToken }
                    });
                    return { success: true, platform: 'Instagram', id: retryRes.data.id, postType: 'CAROUSEL' };
                }
                throw publishErr;
            }
        }

        // ────── CASE 3: SINGLE POST (REEL or IMAGE) ──────
        const url = urls[0];
        const isVid = isVideo(url);
        const params = {
            caption: unifiedCaption,
            access_token: accessToken
        };

        if (isVid) {
            params.video_url = url;
            params.media_type = 'REELS';
            params.share_to_feed = true; 
        } else {
            params.image_url = url;
        }

        console.log(`[INSTAGRAM] Step 1: Creating media container...`);
        const res = await axios.post(`https://graph.facebook.com/v19.0/${igId}/media`, null, { params });
        const creationId = res.data.id;
        
        // Polling is REQUIRED for all media (Images and Videos).
        // Meta needs time to scrape the media from S3 and process it.
        console.log(`[INSTAGRAM] Step 2: Waiting for Meta processing...`);
        await pollStatus(igId, creationId, accessToken, isVid);

        console.log(`[INSTAGRAM] Step 3: Publishing media...`);
        // Add a small optional delay for better reliability after polling
        await new Promise(r => setTimeout(r, 2000));
        
        try {
            const publishRes = await axios.post(`https://graph.facebook.com/v19.0/${igAccountId}/media_publish`, null, {
                params: { creation_id: creationId, access_token: accessToken }
            });
            return { success: true, platform: 'Instagram', id: publishRes.data.id, postType: isVid ? 'REEL' : 'POST' };
        } catch (publishErr) {
            const msg = publishErr.response?.data?.error?.message || publishErr.message;
            if (msg.includes('ready') || msg.includes('available')) {
                console.log(`[INSTAGRAM] Media not quite ready (propagation delay). Retrying once in 5s...`);
                await new Promise(r => setTimeout(r, 5000));
                const retryRes = await axios.post(`https://graph.facebook.com/v19.0/${igAccountId}/media_publish`, null, {
                    params: { creation_id: creationId, access_token: accessToken }
                });
                return { success: true, platform: 'Instagram', id: retryRes.data.id, postType: isVid ? 'REEL' : 'POST' };
            }
            throw publishErr;
        }

    } catch (error) {
        const metaError = error.response?.data?.error?.message || error.message;
        const metaDetail = error.response?.data?.error?.error_user_msg || '';
        console.error('[INSTAGRAM] Publish Error:', metaError, metaDetail);
        throw new Error(`Instagram Error: ${metaError} ${metaDetail}`);
    }
};

exports.disconnect = async (req, res) => {
    const DEFAULT_USER_ID = 'default-user-id';
    await Token.deleteOne({ userId: DEFAULT_USER_ID, platform: 'meta' });
    res.json({ success: true, message: 'Meta disconnected' });
};
