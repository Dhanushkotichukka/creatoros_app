const youtubeController = require('./youtubeController');
const metaController = require('./metaController');
const linkedinController = require('./linkedinController');
const path = require('path');
const fs = require('fs');
const axios = require('axios');

exports.publishToAll = async (req, res) => {
    const { title, platformData, mediaUrls } = req.body;
    const platforms = JSON.parse(platformData || '{}');
    const urls = mediaUrls || [];

    const hasYoutube   = Object.keys(platforms).some(k => k.toLowerCase() === 'youtube');
    const hasInstagram = Object.keys(platforms).some(k => k.toLowerCase() === 'instagram');
    const hasLinkedin  = Object.keys(platforms).some(k => k.toLowerCase() === 'linkedin');

    // Only require media if at least one non-text-only platform is selected
    const needsMedia = hasYoutube || hasInstagram || (hasLinkedin && urls.length > 0);
    if (needsMedia && urls.length === 0) {
        return res.status(400).json({ error: 'No media URLs provided from S3' });
    }

    const results = [];
    // Clean URLs (strip signatures) for display/DB only
    const publicMediaUrls = urls.map(u => u.split('?')[0]);
    console.log(`[PUBLISH] Received ${urls.length} media item(s).`);

    let localTempPaths = [];
    let instagramUrls = urls; // Default: use original signed URLs for Instagram
    
    try {
        const hasYoutube   = Object.keys(platforms).some(k => k.toLowerCase() === 'youtube');
        const hasInstagram = Object.keys(platforms).some(k => k.toLowerCase() === 'instagram');
        const hasLinkedin  = Object.keys(platforms).some(k => k.toLowerCase() === 'linkedin');

        // Download files locally when any platform needs it
        if (urls.length > 0 && (hasYoutube || hasLinkedin || hasInstagram)) {
            console.log(`[PUBLISH] Downloading ${urls.length} item(s) from S3...`);
            
            for (let i = 0; i < urls.length; i++) {
                const dlUrl = urls[i].replace('localhost', '127.0.0.1');
                try {
                    let ext = '';
                    const urlPathname = new URL(dlUrl).pathname;
                    const urlExt = path.extname(urlPathname).toLowerCase();
                    const validExts = ['.mp4', '.mov', '.avi', '.jpg', '.jpeg', '.png', '.gif', '.webp'];
                    if (validExts.includes(urlExt)) ext = urlExt === '.jpeg' ? '.jpg' : urlExt;

                    const response = await axios({ url: dlUrl, method: 'GET', responseType: 'stream', timeout: 15000 });
                    if (!ext) {
                        const ct = response.headers['content-type'] || '';
                        if (ct.includes('image/png'))  ext = '.png';
                        else if (ct.includes('image/jpeg')) ext = '.jpg';
                        else if (ct.includes('image/webp')) ext = '.webp';
                        else if (ct.includes('video/mp4'))  ext = '.mp4';
                        else ext = '.bin';
                    }

                    const localPath = path.join(__dirname, '..', 'uploads', `temp-${Date.now()}-${i}${ext}`);
                    if (!fs.existsSync(path.dirname(localPath))) fs.mkdirSync(path.dirname(localPath), { recursive: true });

                    const { pipeline } = require('stream/promises');
                    await pipeline(response.data, fs.createWriteStream(localPath));
                    localTempPaths.push(localPath);
                } catch (dlErr) {
                    console.error(`[PUBLISH] Download failed for item ${i}:`, dlErr.message);
                }
            }

            // ── Clean Upload for Instagram ────────────────────────────────────
            // Instagram's scraper is extremely sensitive to URL formats. 
            // We re-upload the local temp files with "clean" names and 
            // explicit extensions to any-but-certain Meta successes.
            if (hasInstagram && localTempPaths.length > 0) {
                const isAWSConfigured = process.env.AWS_ACCESS_KEY_ID &&
                    process.env.AWS_ACCESS_KEY_ID !== 'your_aws_access_key_here';

                if (isAWSConfigured) {
                    const s3Service = require('../services/s3Service');
                    const freshUrls = [];

                    for (let idx = 0; idx < localTempPaths.length; idx++) {
                        try {
                            const localPath = localTempPaths[idx];
                            const ext = path.extname(localPath).toLowerCase() || '.jpg';
                            
                            // Map extension to mime type
                            let mimeType = 'image/jpeg';
                            if (ext === '.png') mimeType = 'image/png';
                            else if (ext === '.webp') mimeType = 'image/webp';
                            else if (['.mp4', '.mov', '.avi'].includes(ext)) mimeType = 'video/mp4';

                            const cleanKey = `clean-ig/${Date.now()}-${idx}${ext}`;
                            const fileBuffer = fs.readFileSync(localPath);
                            
                            console.log(`[PUBLISH] Sanitizing for Instagram: ${cleanKey}`);
                            await s3Service.uploadToTempStorage(fileBuffer, cleanKey, mimeType);
                            
                            const longUrl = await s3Service.getPresignedUrl(s3Service.TEMP_BUCKET, cleanKey, 604800);
                            freshUrls.push(longUrl);
                            console.log(`[PUBLISH] ✅ Sanitized S3 URL generated for Instagram (item ${idx})`);
                        } catch (signErr) {
                            console.warn(`[PUBLISH] ⚠️ Sanitization failed for item ${idx}, using original:`, signErr.message);
                            freshUrls.push(urls[idx] || urls[0]);
                        }
                    }
                    instagramUrls = freshUrls;
                } else {
                    console.warn('[PUBLISH] ⚠️ AWS not configured — passing original URLs to Instagram.');
                    instagramUrls = urls;
                }
            }

        } else if (hasLinkedin && urls.length === 0) {
            console.log(`[PUBLISH] No media — LinkedIn text-only post.`);
        }

        // Determine if there's any video in the set
        const hasVideo = localTempPaths.some(p => ['.mp4', '.mov', '.avi', '.webm'].some(e => p.endsWith(e))) ||
                         publicMediaUrls.some(u => ['.mp4', '.mov', '.avi', '.webm'].some(e => u.toLowerCase().endsWith(e)));

        // ── YouTube Publish ──
        if (hasYoutube) {
            const ytKey = Object.keys(platforms).find(k => k.toLowerCase() === 'youtube');
            if (!hasVideo) {
                results.push({ platform: 'YouTube', success: false, error: 'YouTube only supports video uploads.' });
            } else {
                try {
                    const videoPath = localTempPaths.find(p => ['.mp4', '.mov', '.avi', '.webm'].some(e => p.endsWith(e)));
                    const ytRes = await youtubeController.publishToYouTube(videoPath, platforms[ytKey]);
                    results.push(ytRes || { platform: 'YouTube', success: true });
                } catch (err) {
                    results.push({ platform: 'YouTube', success: false, error: err.message });
                }
            }
        }

        // ── Instagram Publish ──
        // Uses clean public URLs (re-uploaded) so Meta's scraper can fetch them
        if (hasInstagram) {
            const igKey = Object.keys(platforms).find(k => k.toLowerCase() === 'instagram');
            try {
                console.log(`[PUBLISH] Instagram using URLs:`, instagramUrls.map(u => u.substring(0, 80)));
                const igRes = await metaController.publishToInstagram(instagramUrls, platforms[igKey]);
                results.push(igRes);
            } catch (err) {
                results.push({ platform: 'Instagram', success: false, error: err.message });
            }
        }

        // ── LinkedIn Publish (Text / Single Image / Video / Carousel) ──
        if (hasLinkedin) {
            const liKey = Object.keys(platforms).find(k => k.toLowerCase() === 'linkedin');
            try {
                // Pass localTempPaths (may be empty for text-only)
                // Pass original signed S3 URLs as 3rd arg for video link-card fallback
                const liRes = await linkedinController.publishToLinkedIn(localTempPaths, platforms[liKey], urls);
                results.push(liRes);
            } catch (err) {
                results.push({ platform: 'LinkedIn', success: false, error: err.message });
            }
        }

        // Save debug logs
        fs.writeFileSync(path.join(__dirname, '../utils/publish_debug.json'), JSON.stringify({ timestamp: new Date().toISOString(), results }, null, 2));

        // Save to Content DB
        try {
            const { Content } = require('../models');
            if (results.some(r => r.success)) {
                const platformMetadata = {};
                results.forEach(res => {
                    if (res.success && res.id) {
                        platformMetadata[res.platform.toLowerCase()] = {
                            id: res.id,
                            syncedAt: new Date(),
                            likes: 0,
                            comments: 0
                        };
                    }
                });

                await Content.create({
                    title: title || 'CreatorOS Multi-Post',
                    description: 'Published via multi-post hub',
                    contentType: hasVideo ? 'video' : (urls.length > 1 ? 'carousel' : 'image'),
                    platforms,
                    status: 'published',
                    mediaUrl: publicMediaUrls[0],
                    thumbnailUrl: hasVideo ? 'https://via.placeholder.com/600x300?text=Video+Thumbnail' : publicMediaUrls[0],
                    publishedAt: new Date(),
                    platformMetadata
                });
            }
        } catch (dbErr) { console.error('[PUBLISH] DB Save Error:', dbErr.message); }

        res.json({ message: 'Publishing process completed', results });

    } catch (error) {
        console.error('[PUBLISH] Global error:', error.message);
        res.status(500).json({ error: 'An unexpected error occurred during publishing.' });
    } finally {
        for (const p of localTempPaths) {
            if (fs.existsSync(p)) fs.unlinkSync(p);
        }
    }
};


