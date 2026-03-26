const express = require('express');
const router = express.Router();
const { Analytics, Content } = require('../models');
const axios = require('axios');
const metaController = require('../controllers/metaController');

const formatViews = (num) => {
    if (num === null || num === undefined) return '0';
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
};

// Unified data aggregator for Analytics Overview
router.get('/overview', async (req, res) => {
    // Check which platforms are connected
    const status = {
        youtube: !!global.youtubeToken,
        instagram: !!global.metaToken,
        linkedin: !!global.linkedinToken
    };
    try {
        let totalViewsNum = 0;
        let platforms = [];
        let topContent = [];

        // 1. YouTube Data Fetching
        let uploadsPlaylistId = null;
        if (global.youtubeToken) {
            try {
                // Fetch dynamic real subscriber/view count from Google using Axios for cross-version stability
                const ytRes = await axios.get('https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet,contentDetails&mine=true', {
                    headers: { Authorization: 'Bearer ' + global.youtubeToken },
                    timeout: 5000
                });
                const ytData = ytRes.data;
                
                if (ytData.items && ytData.items.length > 0) {
                    const channel = ytData.items[0];
                    const views = parseInt(channel.statistics.viewCount) || 0;
                    const subs = parseInt(channel.statistics.subscriberCount) || 0;
                    const vids = parseInt(channel.statistics.videoCount) || 0;
                    
                    uploadsPlaylistId = channel.contentDetails.relatedPlaylists.uploads;
                    totalViewsNum += views;
                    
                    const formatNum = (num) => num >= 1000000 ? (num/1000000).toFixed(1) + 'M' : num >= 1000 ? (num/1000).toFixed(1) + 'K' : num.toString();
                    
                    platforms.push({
                        name: 'YouTube',
                        isConnected: true,
                        views: formatNum(views),
                        subscribers: formatNum(subs),
                        videos: formatNum(vids),
                        channelName: channel.snippet.title,
                        channelAvatar: channel.snippet.thumbnails.default.url,
                        engagement: 'Your Real Data'
                    });
                } else {
                    platforms.push({ name: 'YouTube', isConnected: false });
                }
            } catch (ytError) {
                console.error("YouTube Fetch Error: ", ytError);
                platforms.push({ name: 'YouTube', isConnected: false });
            }
        } else {
            platforms.push({ name: 'YouTube', isConnected: false });
        }

        // 2. Instagram Data Fetching (Strictly isolated)
        let igPlatformObj = { name: 'Instagram', isConnected: false };
        if (global.metaToken && global.igAccountId) {
            try {
                // Fetch IG Details & Media
                const igRes = await axios.get(`https://graph.facebook.com/v19.0/${global.igAccountId}?fields=followers_count,media_count,username,profile_picture_url,media{id,caption,media_type,media_url,thumbnail_url,timestamp,like_count,comments_count,shortcode}&access_token=${global.metaToken}`);
                const igData = igRes.data;
                
                let igViews = 0;
                try {
                    const igInsightsRes = await axios.get(`https://graph.facebook.com/v19.0/${global.igAccountId}/insights?metric=reach&period=day&access_token=${global.metaToken}`);
                    const insights = igInsightsRes.data.data;
                    if (insights && insights.length > 0) {
                        igViews = insights.find(i => i.name === 'reach')?.values[0]?.value || 0;
                    }
                } catch (insightsErr) {
                    console.log("[DIAGNOSTIC] Overview Insights suppressed:", insightsErr.response?.data?.error?.message || insightsErr.message);
                }
                
                totalViewsNum += igViews;

                igPlatformObj = {
                    name: 'Instagram',
                    isConnected: true,
                    views: formatViews(igViews),
                    subscribers: formatViews(igData.followers_count || 0),
                    videos: (igData.media_count || 0).toString(),
                    channelName: '@' + igData.username,
                    channelAvatar: igData.profile_picture_url,
                    engagement: '+5.2%',
                    platformIcon: 'instagram'
                };

                // Add IG media to top content pool
                if (igData.media && igData.media.data) {
                    const igVideos = igData.media.data.map(v => ({
                        id: v.id,
                        title: v.caption ? (v.caption.substring(0, 50) + '...') : 'Instagram Post',
                        viewsNum: (v.like_count || 0) + (v.comments_count || 0),
                        views: formatViews((v.like_count || 0) + (v.comments_count || 0)),
                        likes: (v.like_count || 0).toString(),
                        platform: 'Instagram',
                        type: v.media_type.toLowerCase() === 'video' ? 'video' : 'post',
                        thumbnail: v.thumbnail_url || v.media_url,
                        publishedAt: new Date(v.timestamp)
                    }));
                    topContent = [...topContent, ...igVideos];
                }
            } catch (igErr) {
                console.error("IG Primary Fetch Error (Overview):", igErr.response?.data || igErr.message);
            }
        }
        platforms.push(igPlatformObj);

        // 3. LinkedIn Mock
        platforms.push({ name: 'LinkedIn', isConnected: false });

        let realTimeData = null;

        // Fetch Real Top 10 Content & Estimate 48h Velocity using Uploads Playlist
        if (global.youtubeToken && uploadsPlaylistId) {
            try {
                // Fetch up to 15 recent videos
                const vidRes = await axios.get(`https://www.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails&playlistId=${uploadsPlaylistId}&maxResults=15`, {
                    headers: { Authorization: 'Bearer ' + global.youtubeToken }
                });
                
                if (vidRes.data.items && vidRes.data.items.length > 0) {
                    const videoIds = vidRes.data.items.map(item => item.contentDetails.videoId).join(',');
                    // Fetch real statistics for those videos
                    const statsRes = await axios.get(`https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=${videoIds}`, {
                        headers: { Authorization: 'Bearer ' + global.youtubeToken }
                    });
                    
                    const formatViewsLocal = (num) => num >= 1000000 ? (num/1000000).toFixed(1) + 'M' : num >= 1000 ? (num/1000).toFixed(1) + 'K' : num.toString();

                    const videos = statsRes.data.items.map(v => ({
                        id: v.id,
                        title: v.snippet.title,
                        viewsNum: parseInt(v.statistics.viewCount) || 0,
                        views: formatViewsLocal(parseInt(v.statistics.viewCount) || 0),
                        likes: v.statistics.likeCount || '0',
                        platform: 'YouTube',
                        type: 'video',
                        thumbnail: v.snippet.thumbnails.high ? v.snippet.thumbnails.high.url : v.snippet.thumbnails.default.url,
                        publishedAt: new Date(v.snippet.publishedAt)
                    }));
                    topContent = [...topContent, ...videos];
                    
                    // Combine, sort by views, but guarantee at least 2 from each platform if available
                    const ytVids = topContent.filter(c => c.platform === 'YouTube').sort((a,b) => b.viewsNum - a.viewsNum);
                    const igVids = topContent.filter(c => c.platform === 'Instagram').sort((a,b) => b.viewsNum - a.viewsNum);
                    
                    // Take top 2 from each, then fill rest with top overall
                    const guaranteed = [...ytVids.slice(0, 2), ...igVids.slice(0, 2)];
                    const remaining = topContent.filter(c => !guaranteed.find(g => g.id === c.id))
                                              .sort((a,b) => b.viewsNum - a.viewsNum);
                    
                    topContent = [...guaranteed, ...remaining].slice(0, 10);
                    
                    // Calculate "trending" velocity for RealTime 48h section
                    const recentVideos = [...videos].sort((a,b) => b.publishedAt - a.publishedAt).slice(0, 3);
                    let views48hRaw = 0;
                    
                    const trendingVideos = recentVideos.map(v => {
                        const hoursOld = Math.max(1, (new Date() - v.publishedAt) / (1000 * 60 * 60));
                        const viewsPerHour = Math.round(v.viewsNum / hoursOld);
                        views48hRaw += (viewsPerHour * 48);
                        return {
                           title: v.title,
                           thumbnail: v.thumbnail,
                           subtitle: `${formatViewsLocal(viewsPerHour)} views this hour`
                        };
                    });
                    
                    if (views48hRaw < 50) views48hRaw = Math.max(50, Math.round(totalViewsNum * 0.02)); // Fallback baseline
                    
                    const baseHourly = [12, 15, 8, 20, 25, 40, 35, 30, 45, 60, 55, 65, 80, 75, 90, 110, 105, 95, 85, 70, 50, 40, 30, 20];
                    const sumBase = baseHourly.reduce((a,b)=>a+b, 0);
                    const hourlyViews = baseHourly.map(v => (v / sumBase) * (views48hRaw / 2));
                    
                    realTimeData = {
                        totalViews48h: formatViewsLocal(Math.round(views48hRaw)),
                        hourlyViews: hourlyViews,
                        trendingVideos: trendingVideos
                    };
                }
            } catch (err) {
                console.error("Top Content / Metrics Realtime Parsing Error:", err.message);
            }
        }

        // Helper removed from here to top

        res.json({
            creatorHealth: 'Growing', 
            creatorScore: 98, 
            totalViews: formatViews(totalViewsNum),
            growth: '+20%',
            streak: 15,
            platforms: platforms,
            topContent: topContent,
            realTimeData: realTimeData,
            graphData: {
                views: [100, 200, 300, 400, 500, 600, 700],
                dates: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            }
        });
    } catch (error) {
        console.error('Video analytics error:', error.message);
        res.status(500).json({ error: 'Failed' });
    }
});

router.get('/platforms/status', async (req, res) => {
    try {
        res.json({
            youtube: {
                connected: !!global.youtubeToken,
                name: global.ytChannelName || null,
                avatar: global.ytAvatar || null
            },
            instagram: {
                connected: !!global.metaToken,
                name: global.igUsername ? '@' + global.igUsername : (global.igName || null),
                avatar: global.igAvatar || null
            },
            linkedin: {
                connected: !!global.linkedinToken
            }
        });
    } catch (error) {
        console.error('Platforms status error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Platform specific deep analytics
router.get('/:platform', async (req, res) => {
    const { platform } = req.params;
    let platformData = {};
    let videos = [];
    const formatNum = (num) => num >= 1000000 ? (num/1000000).toFixed(1) + 'M' : num >= 1000 ? (num/1000).toFixed(1) + 'K' : num.toString();

    if (platform.toLowerCase() === 'youtube' && global.youtubeToken) {
        try {
            // 1. Fetch channel metadata
            const ytRes = await axios.get('https://www.googleapis.com/youtube/v3/channels?part=statistics,snippet,contentDetails&mine=true', {
                headers: { Authorization: 'Bearer ' + global.youtubeToken }
            });
            const ytData = ytRes.data;

            if (ytData.items && ytData.items.length > 0) {
                const channel = ytData.items[0];
                const subsNum = parseInt(channel.statistics.subscriberCount) || 0;
                const viewsNum = parseInt(channel.statistics.viewCount) || 0;
                const videosNum = parseInt(channel.statistics.videoCount) || 0;
                const uploadsPlaylistId = channel.contentDetails.relatedPlaylists.uploads;

                // 2. Fetch up to 20 latest videos from uploads playlist
                const vidListRes = await axios.get(`https://www.googleapis.com/youtube/v3/playlistItems?part=snippet,contentDetails&playlistId=${uploadsPlaylistId}&maxResults=20`, {
                    headers: { Authorization: 'Bearer ' + global.youtubeToken }
                });

                let totalLikesNum = 0;
                let watchHours = 'N/A';

                if (vidListRes.data.items && vidListRes.data.items.length > 0) {
                    const videoIds = vidListRes.data.items.map(i => i.contentDetails.videoId).join(',');

                    // 3. Fetch real stats (views, likes, duration) for each video
                    const statsRes = await axios.get(`https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&id=${videoIds}`, {
                        headers: { Authorization: 'Bearer ' + global.youtubeToken }
                    });

                    let totalWatchSeconds = 0;

                    videos = statsRes.data.items.map(v => {
                        const likes = parseInt(v.statistics.likeCount) || 0;
                        const vViews = parseInt(v.statistics.viewCount) || 0;
                        totalLikesNum += likes;

                        // Parse ISO 8601 duration to seconds (e.g. PT5M30S → 330s)
                        const dur = v.contentDetails.duration || 'PT0S';
                        const durMatch = dur.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
                        const durSecs = (parseInt(durMatch?.[1] || 0) * 3600) + (parseInt(durMatch?.[2] || 0) * 60) + parseInt(durMatch?.[3] || 0);
                        totalWatchSeconds += durSecs * vViews;

                        return {
                            id: v.id,
                            title: v.snippet.title,
                            thumbnail: v.snippet.thumbnails.high ? v.snippet.thumbnails.high.url : v.snippet.thumbnails.default.url,
                            publishedAt: v.snippet.publishedAt,
                            views: formatNum(vViews),
                            viewsNum: vViews,
                            likes: formatNum(likes),
                            platform: 'YouTube',
                            type: 'video',
                        };
                    });

                    // Estimate watch hours from video views × duration
                    const watchHoursNum = Math.round(totalWatchSeconds / 3600);
                    watchHours = watchHoursNum >= 1000 ? (watchHoursNum / 1000).toFixed(1) + 'K hrs' : watchHoursNum + ' hrs';
                }

                // 4. Try YouTube Analytics API for real watch time (may require extra OAuth scope)
                try {
                    const today = new Date();
                    const startDate = new Date(today); startDate.setDate(today.getDate() - 28);
                    const toISO = (d) => d.toISOString().split('T')[0];
                    const analyticsRes = await axios.get(
                        `https://youtubeanalytics.googleapis.com/v2/reports?ids=channel==MINE&startDate=${toISO(startDate)}&endDate=${toISO(today)}&metrics=estimatedMinutesWatched,views,likes,subscribersGained&dimensions=day`,
                        { headers: { Authorization: 'Bearer ' + global.youtubeToken } }
                    );
                    if (analyticsRes.data.rows) {
                        let totalMins = 0, totalLikesAnalytics = 0;
                        analyticsRes.data.rows.forEach(r => { totalMins += r[1] || 0; totalLikesAnalytics += r[3] || 0; });
                        const hrs = Math.round(totalMins / 60);
                        watchHours = hrs >= 1000 ? (hrs / 1000).toFixed(1) + 'K hrs (28d)' : `${hrs} hrs (28d)`;
                        if (totalLikesAnalytics > 0) totalLikesNum = totalLikesAnalytics;
                    }
                } catch (analyticsErr) {
                    // Analytics API not granted — keep estimated value
                    console.log('YouTube Analytics API unavailable (scope not granted), using estimated watch hours.');
                }

                platformData = {
                    name: channel.snippet.title,
                    avatar: channel.snippet.thumbnails.default.url,
                    subscribers: formatNum(subsNum),
                    totalViews: formatNum(viewsNum),
                    totalLikes: formatNum(totalLikesNum),
                    videos: formatNum(videosNum),
                    watchTime: watchHours,
                    creatorHealth: 'Growing',
                    streak: 15,
                    growth: '+12%',
                    engagementRate: 0.06
                };
            }
        } catch (e) {
            console.error('YouTube Deep Analytics Error', e.message);
        }
    } else if (platform.toLowerCase() === 'instagram' && global.metaToken && global.igAccountId) {
        try {
            // Fetch IG Details & Media
            const igRes = await axios.get(`https://graph.facebook.com/v19.0/${global.igAccountId}?fields=followers_count,media_count,username,name,profile_picture_url,media{id,caption,media_type,media_url,thumbnail_url,timestamp,like_count,comments_count,shortcode}&access_token=${global.metaToken}`);
            const igData = igRes.data;

            platformData = {
                name: igData.name || igData.username,
                avatar: igData.profile_picture_url,
                subscribers: formatNum(igData.followers_count || 0),
                totalViews: formatNum(igData.media_count || 0), // Use post count as placeholder for views if insights restricted
                totalLikes: 'N/A',
                videos: formatNum(igData.media_count || 0),
                watchTime: 'N/A',
                creatorHealth: 'Healthy',
                streak: 7,
                growth: '+5.2%',
                engagementRate: 0.045
            };

            if (igData.media && igData.media.data) {
                videos = igData.media.data.map(v => ({
                    id: v.id,
                    title: v.caption ? (v.caption.substring(0, 50) + '...') : 'Instagram Post',
                    thumbnail: v.thumbnail_url || v.media_url,
                    publishedAt: v.timestamp,
                    views: formatNum((v.like_count || 0) + (v.comments_count || 0)),
                    likes: formatNum(v.like_count || 0),
                    platform: 'Instagram',
                    type: v.media_type.toLowerCase() === 'video' ? 'video' : 'post',
                }));
            }

            // Try fetching real insights (requires business type)
            try {
                const igInsightsRes = await axios.get(`https://graph.facebook.com/v19.0/${global.igAccountId}/insights?metric=reach,profile_views&period=day&access_token=${global.metaToken}`);
                if (igInsightsRes.data.data) {
                    const insights = igInsightsRes.data.data;
                    const reach = insights.find(i => i.name === 'reach')?.values[0]?.value || 0;
                    platformData.totalViews = formatNum(reach);
                }
            } catch (insightsErr) {
                console.log("IG Insights restricted (Deep):", insightsErr.response?.data?.error?.message || insightsErr.message);
            }

        } catch (e) {
            console.error('Instagram Deep Analytics Error:', e.response?.data || e.message);
        }
    }

    // Fallback mock if not connected or error
    if (Object.keys(platformData).length === 0) {
        platformData = {
            name: platform,
            avatar: 'https://via.placeholder.com/150',
            subscribers: '—',
            totalViews: '—',
            totalLikes: '—',
            videos: '—',
            watchTime: '—',
            creatorHealth: 'Neutral',
            streak: 0,
            growth: '—',
            engagementRate: 0
        };
        videos = [];
    }

    res.json({
        platform,
        platformData,
        videos,
        deepMetrics: {
            watchRetention: [100, 80, 75, 60, 45, 40, 30],
            audienceAge: { '18-24': 30, '25-34': 50, '35-44': 15, '45+': 5 },
            trafficSources: { search: 40, suggested: 35, external: 15, browse: 10 }
        }
    });
});

// Individual Video Deep Analytics
router.get('/video/:id', async (req, res) => {
    const { id } = req.params;
    let videoData = {};

    if (global.youtubeToken) {
        try {
            const vidRes = await axios.get(`https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,status,contentDetails&id=${id}`, {
                headers: { Authorization: 'Bearer ' + global.youtubeToken }
            });
            if (vidRes.data.items && vidRes.data.items.length > 0) {
                const vid = vidRes.data.items[0];
                videoData = {
                    id: vid.id,
                    title: vid.snippet.title,
                    thumbnail: vid.snippet.thumbnails.maxres ? vid.snippet.thumbnails.maxres.url : vid.snippet.thumbnails.high ? vid.snippet.thumbnails.high.url : vid.snippet.thumbnails.default.url,
                    publishedAt: vid.snippet.publishedAt,
                    views: vid.statistics.viewCount,
                    likes: vid.statistics.likeCount,
                    commentsCount: vid.statistics.commentCount,
                    visibility: vid.status.privacyStatus,
                    quality: vid.contentDetails.definition === 'hd' ? 'HD' : 'SD',
                    restrictions: vid.contentDetails.contentRating ? 'Age Restricted' : 'No restrictions',
                    category: vid.snippet.categoryId,
                    monetisation: 'Monetised (Simulated)',
                };
            }
        } catch (e) {
            console.error("Video Fetch Error", e.message);
        }
    }

    if (Object.keys(videoData).length === 0) {
        // Mock Video Data for unlinked accounts
        videoData = {
            id,
            title: 'Mock Video Analysis - Deep Dive',
            thumbnail: 'https://via.placeholder.com/600x300',
            publishedAt: new Date().toISOString(),
            views: '45.2K',
            likes: '3.1K',
            commentsCount: '150',
            visibility: 'Public',
            quality: '4K',
            restrictions: 'No restrictions',
            category: 'Tech',
            monetisation: 'Monetised'
        };
    }

    res.json({
        video: videoData,
        aiInsights: [
            "Low CTR detected — thumbnail may lack a strong visual hook or contrasting colours",
            "Average view duration is 2.3 minutes on a 10-minute video — hook strength is low",
            "Try adding a pattern interrupt in the first 5 seconds to reduce early drop-off",
            "This video performs 40% better with mobile viewers than desktop — consider portrait-format version"
        ],
        earlyPerformance: {
            timeSinceUpload: '4 days 3 hours',
            views: '3,000',
            impressionRate: '1.2%',
            subGain: '+45',
            commentsToViews: '0.8%'
        },
        comments: [
            { author: '@user123', text: 'This feature completely saved my workflow!', sentiment: 'Positive' },
            { author: '@critic99', text: 'Audio balancing is a little off in this one.', sentiment: 'Neutral' }
        ],
        deepMetrics: {
            audienceAge: { '13-17': 5, '18-24': 35, '25-34': 40, '35-44': 15, '45+': 5 },
            locations: ['USA', 'India', 'UK', 'Canada', 'Australia'],
            trafficSources: { search: 50, suggested: 30, external: 10, browse: 10 },
            watchRetention: [100, 80, 75, 60, 45, 40, 30],
            impressions: '120K',
            ctr: '4.5%',
            avgViewDuration: '3:15'
        }
    });
});

module.exports = router;
