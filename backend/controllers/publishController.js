const youtubeController = require('./youtubeController');
const metaController = require('./metaController');
const path = require('path');
const fs = require('fs');
const axios = require('axios');

exports.publishToAll = async (req, res) => {
    const { title, platformData, mediaUrls } = req.body;
    const platforms = JSON.parse(platformData || '{}');
    const urls = mediaUrls || [];

    if (urls.length === 0) {
        return res.status(400).json({ error: 'No media URLs provided from S3' });
    }

    const results = [];
    const mainMediaUrl = urls[0];
    
    // We'll construct a temporary local file path for platforms like YouTube that require a local stream
    let localTempPath = null;
    
    try {
        // Only download if YouTube is selected, since Instagram natively accepts public URLs
        // Note: Checking dictionary with lower case since frontend json passes it as 'youtube' or 'instagram' due to .name on enum 
        const hasYoutube = Object.keys(platforms).some(k => k.toLowerCase() === 'youtube');
        const hasInstagram = Object.keys(platforms).some(k => k.toLowerCase() === 'instagram');

        if (hasYoutube) {
            localTempPath = path.join(__dirname, '..', 'uploads', `temp-media-${Date.now()}.mp4`);
            
            // Ensure uploads directory exists properly (fs may be finicky occasionally on windows)
            const uploadDir = path.dirname(localTempPath);
            if (!fs.existsSync(uploadDir)) {
                fs.mkdirSync(uploadDir, { recursive: true });
            }

            console.log('Downloading media from S3 for local publishing buffer...');
            
            // In dev environment when calling localhost dynamically, we map to 127.0.0.1 
            // In prod this will just be your S3 URL directly.
            const dlUrl = mainMediaUrl.replace('localhost', '127.0.0.1');

            try {
                const response = await axios({
                    url: dlUrl,
                    method: 'GET',
                    responseType: 'stream',
                    timeout: 10000 // 10s timeout
                });

                const { pipeline } = require('stream/promises');
                await pipeline(response.data, fs.createWriteStream(localTempPath));
                console.log('Finished downloading to temp buffer.');
            } catch (dlErr) {
                console.error('[PUBLISH] S3 Download Failed:', dlErr.message);
                // If it's a "Bucket not found" or "404", we should return a meaningful error
                throw new Error(`Media stored in S3 is not reachable: ${dlErr.message}`);
            }
        }

        // YouTube Publish
        if (hasYoutube) {
            console.log('[PUBLISH] Starting YouTube publishing...');
            const ytKey = Object.keys(platforms).find(k => k.toLowerCase() === 'youtube');
            try {
                const ytRes = await youtubeController.publishToYouTube(localTempPath, platforms[ytKey]);
                results.push(ytRes || { platform: 'YouTube', success: true });
            } catch (err) {
                console.error('[PUBLISH] YouTube Error:', err.message);
                results.push({ platform: 'YouTube', success: false, error: err.message });
            }
        }

        // Instagram Publish
        if (hasInstagram) {
            const igKey = Object.keys(platforms).find(k => k.toLowerCase() === 'instagram');
            try {
                // Pass the native S3 public URL directly to Meta
                const igRes = await metaController.publishToInstagram(mainMediaUrl, platforms[igKey]);
                results.push(igRes);
            } catch (err) {
                results.push({ platform: 'Instagram', success: false, error: err.message });
            }
        }

        const finalResults = {
            timestamp: new Date().toISOString(),
            mediaUrl: mainMediaUrl,
            platforms: platforms,
            results: results
        };
        fs.writeFileSync(path.join(__dirname, '../utils/publish_debug.json'), JSON.stringify(finalResults, null, 2));

        res.json({
            message: 'Publishing process completed',
            results
        });

    } catch (error) {
        console.error('Unified Publish error:', error);
        res.status(500).json({ error: 'An unexpected error occurred during publishing.' });
    } finally {
        // Clean up temporary local files
        if (localTempPath && fs.existsSync(localTempPath)) {
            fs.unlinkSync(localTempPath);
        }
    }
};
