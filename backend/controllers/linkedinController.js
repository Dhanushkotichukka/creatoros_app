const axios = require('axios');
const fs = require('fs');
const path = require('path');
const https = require('https');
const Token = require('../models/Token');
require('dotenv').config();

// Persistent agent to force IPv4 and reduce SSL handshake overhead
const ipv4Agent = new https.Agent({ family: 4, keepAlive: true });

const CLIENT_ID = process.env.LINKEDIN_CLIENT_ID;
const CLIENT_SECRET = process.env.LINKEDIN_CLIENT_SECRET;
const REDIRECT_URI = 'http://localhost:3000/auth/linkedin/callback';

exports.getLoginUrl = (req, res) => {
    const scopes = ['openid', 'profile', 'email', 'w_member_social'];
    const url = `https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${scopes.join('%20')}`;
    res.json({ url });
};

// Helper to decode JWT (OIDC payload) without external library
const decodeJWT = (token) => {
    try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(Buffer.from(base64, 'base64').toString().split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    } catch (e) {
        return null;
    }
};

exports.handleCallback = async (req, res) => {
    const { code, error, error_description } = req.query;
    
    if (error) {
        return res.status(400).send(`LinkedIn OAuth Error: ${error_description || error}`);
    }
    
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
        const idToken = tokenResponse.data.id_token;

        let linkedinUserUrn = null;
        let linkedinName = null;
        let linkedinAvatar = null;

        if (idToken) {
            const decoded = decodeJWT(idToken);
            if (decoded) {
                linkedinUserUrn = `urn:li:person:${decoded.sub}`;
                linkedinName = decoded.name || (decoded.given_name ? `${decoded.given_name} ${decoded.family_name || ''}` : null);
                linkedinAvatar = decoded.picture;
                console.log('LinkedIn Profile loaded from ID Token.');
            }
        }

        if (!linkedinUserUrn) {
            try {
                const profileRes = await axios.get('https://api.linkedin.com/userinfo', {
                    headers: { 'Authorization': `Bearer ${accessToken}` }
                });
                const profile = profileRes.data;
                linkedinUserUrn = `urn:li:person:${profile.sub}`;
                linkedinName = profile.name;
                linkedinAvatar = profile.picture;
            } catch (profileErr) {
                console.error('LinkedIn Sync Error:', profileErr.response?.data || profileErr.message);
                try {
                    const legacyRes = await axios.get('https://api.linkedin.com/v2/me', {
                        headers: { 'Authorization': `Bearer ${accessToken}` }
                    });
                    linkedinUserUrn = `urn:li:person:${legacyRes.data.id}`;
                    linkedinName = `${legacyRes.data.localizedFirstName || ''} ${legacyRes.data.localizedLastName || ''}`.trim();
                } catch (legacyErr) {}
            }
        }

        const DEFAULT_USER_ID = 'default-user-id';
        let tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'linkedin' });
        if (!tokenDoc) {
             tokenDoc = new Token({ userId: DEFAULT_USER_ID, platform: 'linkedin', accessToken });
        } else {
             tokenDoc.accessToken = accessToken;
        }
        tokenDoc.platformAccountId = linkedinUserUrn;
        tokenDoc.platformAccountName = linkedinName;
        tokenDoc.profileAvatar = linkedinAvatar;
        await tokenDoc.save();

        res.send(`
            <html>
            <body style="display:flex; justify-content:center; align-items:center; height:100vh; font-family:sans-serif; background:#f4f4f9; margin:0;">
              <div style="text-align:center; padding: 40px; background:white; border-radius:12px; box-shadow:0 10px 25px rgba(0,0,0,0.05);">
                <h1 style="color:#0077B5; font-size:32px;">💼 LinkedIn Linked!</h1>
                <p style="font-size:18px; color:#555;">Welcome, ${linkedinName || 'Professional'}!</p>
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

/**
 * Publishes content to LinkedIn (Personal Profile)
 * Strategy:
 *   1. Try to register + upload media via /rest/images or /rest/videos
 *   2. If Step 1 times out or fails → fall back to text-only ugcPost
 */
exports.publishToLinkedIn = async (localMediaPaths, metadata, originalUrls = [], userId = 'default-user-id') => {
    const tokenDoc = await Token.findOne({ userId, platform: 'linkedin' });
    if (!tokenDoc?.accessToken || !tokenDoc?.platformAccountId) {
        throw new Error('LinkedIn not connected or profile info missing');
    }

    const paths = Array.isArray(localMediaPaths) ? localMediaPaths : [localMediaPaths];
    const accessToken = tokenDoc.accessToken;
    const author = tokenDoc.platformAccountId; // e.g. urn:li:person:ABC123

    const isVideoFile = (p) => {
        const ext = (p || '').toLowerCase().split('?')[0].split('.').pop();
        return ['mp4', 'mov', 'avi', 'webm', 'mkv', 'wmv'].includes(ext);
    };

    const videosCount = paths.filter(p => isVideoFile(p)).length;
    if (videosCount > 1) {
        throw new Error('LinkedIn only allows one video per post.');
    }

    console.log(`[LINKEDIN] Publishing ${paths.length} item(s) (Videos: ${videosCount})...`);

    // ── Guard: LinkedIn carousel max 9 images ─────────────────────────────────
    const imagesCount = paths.length - videosCount;
    if (imagesCount > 9) {
        throw new Error('LinkedIn supports a maximum of 9 images per post.');
    }

    // ── Determine post type up front ─────────────────────────────────────────
    const postTypeLabel = paths.length === 0 ? 'TEXT-ONLY'
        : videosCount > 0 ? 'VIDEO'
        : paths.length > 1 ? `CAROUSEL (${paths.length} images)`
        : 'SINGLE IMAGE';
    console.log(`[LINKEDIN] Post type: ${postTypeLabel}`);

    // ── Common headers ────────────────────────────────────────────────────────
    // Use 202501 — a stable, deployed LinkedIn API version
    const commonHeaders = {
        'Authorization': `Bearer ${accessToken}`,
        'X-Restli-Protocol-Version': '2.0.0',
        'LinkedIn-Version': '202501',
        'Content-Type': 'application/json',
    };
    
    // Legacy v2 endpoints do not support the LinkedIn-Version header
    const legacyHeaders = { ...commonHeaders };
    delete legacyHeaders['LinkedIn-Version'];
    
    // Global axios config for this request chain
    const axiosOpts = { httpsAgent: ipv4Agent, timeout: 60000 };

    // ── Helper: text-only UGC post ───────────────────────────────────────────
    const buildPostText = () =>
        `${metadata.title ? metadata.title.toUpperCase() + '\n\n' : ''}${metadata.description || ''}`.trim();

    const postTextOnly = async () => {
        const payload = {
            author,
            lifecycleState: 'PUBLISHED',
            specificContent: {
                'com.linkedin.ugc.ShareContent': {
                    shareCommentary: { text: buildPostText() || 'Posted via CreatorOS 🚀' },
                    shareMediaCategory: 'NONE',
                },
            },
            visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' },
        };
        const postRes = await axios.post('https://api.linkedin.com/v2/ugcPosts', payload, {
            headers: commonHeaders, timeout: 15000,
        });
        const id = postRes.data?.id || postRes.headers?.['x-restli-id'] || 'urn:li:share:success';
        console.log(`[LINKEDIN] ✅ Text-only post SUCCESS. ID: ${id}`);
        return { success: true, platform: 'LinkedIn', id, note: 'Media upload skipped — text post used as fallback' };
    };

    // ── Helper: video as ARTICLE link card (Tier 3 video fallback) ────────────
    // Used when binary video upload is blocked (ETIMEDOUT). Posts the S3 URL as
    // a LinkedIn article/link card so the post still goes through with media context.
    const postVideoAsLink = async (videoUrl) => {
        console.log(`[LINKEDIN] [T3] Posting video as ARTICLE link card: ${videoUrl?.substring(0, 80)}...`);
        const text = buildPostText();
        const payload = {
            author,
            lifecycleState: 'PUBLISHED',
            specificContent: {
                'com.linkedin.ugc.ShareContent': {
                    shareCommentary: { text: text || '🎬 New video via CreatorOS 🚀' },
                    shareMediaCategory: 'ARTICLE',
                    media: [{
                        status: 'READY',
                        originalUrl: videoUrl,
                        title: { text: metadata.title || 'Video Post' },
                        description: { text: metadata.description || 'Shared via CreatorOS' },
                    }],
                },
            },
            visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' },
        };
        try {
            const postRes = await axios.post('https://api.linkedin.com/v2/ugcPosts', payload, {
                headers: commonHeaders, timeout: 15000,
            });
            const id = postRes.data?.id || postRes.headers?.['x-restli-id'] || 'urn:li:share:success';
            console.log(`[LINKEDIN] [T3] ✅ Video link card post SUCCESS. ID: ${id}`);
            return { success: true, platform: 'LinkedIn', id, note: 'Video posted as link card (binary upload not available from current network)' };
        } catch (linkErr) {
            console.error(`[LINKEDIN] [T3] ❌ Link card also failed:`, linkErr.response?.data || linkErr.message);
            console.warn(`[LINKEDIN] [T3] Falling back to text-only.`);
            return await postTextOnly();
        }
    };

    // ── No media paths: post text only ───────────────────────────────────────
    if (paths.length === 0) {
        return await postTextOnly();
    }

    const registeredAssets = [];

    for (const mediaPath of paths) {
        const isVid = isVideoFile(mediaPath);
        const mediaType = isVid ? 'video' : 'image';
        const fileName = path.basename(mediaPath);

        let assetUrn, uploadUrl;

        // ═══════════════════════════════════════════════════════════════════════
        // TIER 1: New REST API  (/rest/images  or  /rest/videos)
        // ═══════════════════════════════════════════════════════════════════════
        console.log(`[LINKEDIN] [T1] Initialising ${mediaType} via /rest API for "${fileName}"`);
        try {
            let initRes;
            if (isVid) {
                const stats = fs.statSync(mediaPath);
                initRes = await axios.post(
                    'https://api.linkedin.com/rest/videos?action=initializeUpload',
                    { initializeUploadRequest: { owner: author, fileSizeBytes: stats.size, uploadCaptions: false, uploadThumbnail: false } },
                    { headers: { ...commonHeaders, 'X-RestLi-Method': 'action' }, ...axiosOpts }
                );
            } else {
                initRes = await axios.post(
                    'https://api.linkedin.com/rest/images?action=initializeUpload',
                    { initializeUploadRequest: { owner: author } },
                    { headers: { ...commonHeaders, 'X-RestLi-Method': 'action' }, ...axiosOpts }
                );
            }

            const value = initRes.data?.value;
            if (!value) throw new Error('Empty init body');

            uploadUrl = value.uploadUrl || value.uploadInstructions?.[0]?.uploadUrl;
            assetUrn  = isVid ? value.video : value.image;

            if (!uploadUrl || !assetUrn) throw new Error('No uploadUrl/assetUrn in REST response');
            console.log(`[LINKEDIN] [T1] ✅ Init OK. Asset: ${assetUrn}`);

        } catch (restErr) {
            const code   = restErr.code;
            const status = restErr.response?.status;
            console.warn(`[LINKEDIN] [T1] ⚠️  REST API failed (${code || status}). Trying legacy /v2/assets...`);

            // ═══════════════════════════════════════════════════════════════════
            // TIER 2: Legacy v2 registerUpload  (/v2/assets?action=registerUpload)
            // Same v2 cluster as ugcPosts — works when /rest is unreachable
            // ═══════════════════════════════════════════════════════════════════
            try {
                const recipe = isVid
                    ? 'urn:li:digitalmediaRecipe:feedshare-video'
                    : 'urn:li:digitalmediaRecipe:feedshare-image';

                const regRes = await axios.post(
                    'https://api.linkedin.com/v2/assets?action=registerUpload',
                    {
                        registerUploadRequest: {
                            recipes: [recipe],
                            owner: author,
                            serviceRelationships: [{
                                relationshipType: 'OWNER',
                                identifier: 'urn:li:userGeneratedContent',
                            }],
                        },
                    },
                    { headers: legacyHeaders, ...axiosOpts }
                );

                const regValue = regRes.data?.value;
                if (!regValue) throw new Error('Empty legacy register response');

                // Legacy response schema
                assetUrn  = regValue.asset;
                uploadUrl = regValue.uploadMechanism?.['com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest']?.uploadUrl;

                if (!uploadUrl || !assetUrn) {
                    console.error('[LINKEDIN] [T2] Unknown schema:', JSON.stringify(regValue, null, 2));
                    throw new Error('No uploadUrl/assetUrn in legacy response');
                }
                console.log(`[LINKEDIN] [T2] ✅ Legacy init OK. Asset: ${assetUrn}`);

            } catch (legacyErr) {
                const lcode   = legacyErr.code;
                const lstatus = legacyErr.response?.status;
                console.error(`[LINKEDIN] [T2] ❌ Legacy also failed (${lcode || lstatus}).`);
                console.error(`[LINKEDIN] [T2] Detail:`, JSON.stringify(legacyErr.response?.data || legacyErr.message));

                if (isVid) {
                    // ═══════════════════════════════════════════════════════════════
                    // TIER 3 (Video only): Post as ARTICLE link card using S3 URL
                    // Binary video upload is blocked from this network. The S3 URL
                    // is shared as a link card so the post still has media context.
                    // ═══════════════════════════════════════════════════════════════
                    const pathIndex = paths.indexOf(mediaPath);
                    const videoUrl  = originalUrls[pathIndex] || originalUrls[0];
                    if (videoUrl) {
                        return await postVideoAsLink(videoUrl);
                    }
                }

                console.warn('[LINKEDIN] [T2] Falling back to text-only.');
                return await postTextOnly();
            }
        }

        // ── Binary upload (same for both tiers) ──────────────────────────────
        console.log(`[LINKEDIN] Step 2: Uploading binary...`);
        try {
            const stats  = fs.statSync(mediaPath);
            const stream = fs.createReadStream(mediaPath);
            await axios.put(uploadUrl, stream, {
                headers: { 'Content-Type': 'application/octet-stream', 'Content-Length': stats.size },
                maxBodyLength: Infinity,
                maxContentLength: Infinity,
                ...axiosOpts
            });
            console.log(`[LINKEDIN] Step 2: ✅ Binary uploaded.`);
        } catch (uploadErr) {
            console.error(`[LINKEDIN] ❌ Step 2 upload failed:`, uploadErr.message);
            return await postTextOnly();
        }

        // ── Poll (REST only; skip for legacy asset URNs) ──────────────────────
        const isRestUrn = assetUrn.startsWith('urn:li:image:') || assetUrn.startsWith('urn:li:video:');
        if (isRestUrn) {
            console.log(`[LINKEDIN] Step 3: Polling ${mediaType} status...`);
            try {
                await pollLinkedInStatus(assetUrn, accessToken, isVid);
            } catch (pollErr) {
                console.warn(`[LINKEDIN] ⚠️  Poll failed: ${pollErr.message}. Continuing anyway.`);
            }
        } else {
            // Legacy assets are immediately available after upload
            console.log(`[LINKEDIN] Step 3: Legacy asset — no polling needed.`);
            await new Promise(r => setTimeout(r, 3000)); // brief settle time
        }

        const assetObj = {
            status: 'READY',
            media: assetUrn
        };
        // Per-item titles are rejected for IMAGE category in ugcPosts (Reserved for ARTICLE/VIDEO)
        if (videosCount > 0) {
            assetObj.title = { text: metadata.title || 'CreatorOS Media' };
        }
        registeredAssets.push(assetObj);
    }

    // ── Final Step: Create the ugcPost ───────────────────────────────────────
    console.log(`[LINKEDIN] Final Step: Creating media post...`);
    const shareMediaCategory = videosCount > 0 ? 'VIDEO' : 'IMAGE';
    const postText = `${metadata.title ? metadata.title.toUpperCase() + '\n\n' : ''}${metadata.description || ''}`.trim();

    const ugcPayload = {
        author,
        lifecycleState: 'PUBLISHED',
        specificContent: {
            'com.linkedin.ugc.ShareContent': {
                shareCommentary: { text: postText || 'Posted via CreatorOS 🚀' },
                shareMediaCategory,
                media: registeredAssets,
            },
        },
        visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' },
    };

    try {
        const postRes = await axios.post('https://api.linkedin.com/v2/ugcPosts', ugcPayload, {
            headers: legacyHeaders,
            ...axiosOpts,
        });
        const finalId = postRes.data?.id || postRes.headers?.['x-restli-id'] || 'urn:li:share:success';
        console.log(`[LINKEDIN] ✅ Media post SUCCESS! ID: ${finalId}`);
        return { success: true, platform: 'LinkedIn', id: finalId };
    } catch (postErr) {
        console.error('[LINKEDIN] ❌ Media ugcPost failed:', JSON.stringify(postErr.response?.data || postErr.message, null, 2));
        console.warn('[LINKEDIN] ⚠️  Last-chance text-only fallback...');
        return await postTextOnly();
    }
};

async function pollLinkedInStatus(assetUrn, token, isVid) {
    const mediaLabel = isVid ? 'Video' : 'Image';
    const maxTries = 30;
    const cleanUrn = assetUrn.replace(/^urn:li:(image|video):/, '');
    const endpoint = isVid
        ? `https://api.linkedin.com/rest/videos/${cleanUrn}`
        : `https://api.linkedin.com/rest/images/${cleanUrn}`;

    for (let i = 0; i < maxTries; i++) {
        await new Promise(r => setTimeout(r, 4000));
        try {
            const res = await axios.get(endpoint, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'X-Restli-Protocol-Version': '2.0.0',
                    'LinkedIn-Version': '202501',
                },
                ...axiosOpts
            });
            const status = res.data?.status || res.data?.downloadStatus;
            console.log(`[LINKEDIN] ${mediaLabel} status: ${status} (attempt ${i + 1})`);
            if (['AVAILABLE', 'READY', 'PROCESSED'].includes(status)) return true;
            if (['FAILED', 'ERROR'].includes(status)) throw new Error(`LinkedIn ${mediaLabel} processing failed: ${status}`);
        } catch (e) {
            if (e.message.includes('failed')) throw e; // re-throw processing failures
            // silently retry network/transient errors
        }
    }
    throw new Error('LinkedIn media processing timed out after polling');
}

exports.getLinkedInAnalytics = async (req, res) => {
    const DEFAULT_USER_ID = 'default-user-id';
    const tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'linkedin' });
    const authorUrn = req.query.organizationUrn || tokenDoc?.platformAccountId;
    const accessToken = req.headers.authorization?.split(' ')[1] || tokenDoc?.accessToken;

    if (!authorUrn || !accessToken) return res.status(400).json({ error: 'No credentials' });

    try {
        let stats = { platform: 'LinkedIn', followerStats: {}, engagementStats: {} };
        const apiHeaders = { 'Authorization': `Bearer ${accessToken}`, 'LinkedIn-Version': '202602', 'X-Restli-Protocol-Version': '2.0.0' };
        
        if (authorUrn.includes(':organization:')) {
            const response = await axios.get(`https://api.linkedin.com/rest/organizationalEntityFollowerStatistics?q=organizationalEntity&organizationalEntity=${encodeURIComponent(authorUrn)}`, { headers: apiHeaders });
            stats.followerStats = response.data;
        } else {
            stats.followerStats = { followersCount: 0 }; 
        }
        res.json(stats);
    } catch (error) {
        res.status(500).json({ error: 'Permission Restricted' });
    }
};

exports.fetchRecentPosts = async (accessToken, authorUrn) => {
    try {
        const apiHeaders = { 
            'Authorization': `Bearer ${accessToken}`, 
            'X-Restli-Protocol-Version': '2.0.0'
        };
        let posts = [];
        try {
            // Tier 1: Try UGC Posts API (v2)
            const response = await axios.get(`https://api.linkedin.com/v2/ugcPosts?q=authors&authors=List(${encodeURIComponent(authorUrn)})&count=10`, { 
                headers: apiHeaders, 
                timeout: 10000,
                httpsAgent: ipv4Agent 
            });
            posts = response.data.elements || [];
        } catch (ugcErr) {
            try {
                // Tier 2: Try older Shares API (v2)
                const shareRes = await axios.get(`https://api.linkedin.com/v2/shares?q=owners&owners=List(${encodeURIComponent(authorUrn)})&count=10`, { 
                    headers: apiHeaders, 
                    timeout: 10000,
                    httpsAgent: ipv4Agent 
                });
                posts = shareRes.data.elements || [];
            } catch (shareErr) {
                // If both fail, throw so the router can trigger DB fallback
                throw new Error('LINKEDIN_API_RESTRICTED');
            }
        }

        console.log(`[SYNC] LinkedIn found ${posts.length} posts`);
        return posts.map(p => {
            let desc = 'LinkedIn Post';
            const c = p.specificContent?.['com.linkedin.ugc.ShareContent'];
            if (c && c.shareCommentary) desc = c.shareCommentary.text;
            else if (p.commentary) desc = p.commentary;
            else if (p.text?.text) desc = p.text.text;

            return {
                id: p.id || p.activity,
                title: desc.substring(0, 60),
                description: desc,
                platform: 'LinkedIn',
                type: 'post',
                publishedAt: p.firstPublishedAt ? new Date(p.firstPublishedAt) : (p.created?.time ? new Date(p.created.time) : new Date()), 
                thumbnail: 'https://cdn-icons-png.flaticon.com/512/174/174857.png'
            };
        });
    } catch (err) {
        console.warn(`[SYNC] LinkedIn API restricted or failed: ${err.message}`);
        throw new Error('LINKEDIN_RESTRICTED');
    }
};

exports.getStatus = async (req, res) => {
    const DEFAULT_USER_ID = 'default-user-id';
    const tokenDoc = await Token.findOne({ userId: DEFAULT_USER_ID, platform: 'linkedin' });
    res.json({ connected: !!tokenDoc?.accessToken, name: tokenDoc?.platformAccountName, avatar: tokenDoc?.profileAvatar, urn: tokenDoc?.platformAccountId });
};

exports.disconnect = async (req, res) => {
    const DEFAULT_USER_ID = 'default-user-id';
    await Token.deleteOne({ userId: DEFAULT_USER_ID, platform: 'linkedin' });
    res.json({ success: true, message: 'LinkedIn disconnected' });
};
