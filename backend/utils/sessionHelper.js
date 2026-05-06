const fs = require('fs');
const path = require('path');

const sessionPath = path.join(__dirname, '..', 'session_store.json');

function saveSessions() {
    const data = {
        youtubeToken: global.youtubeToken,
        youtubeRefreshToken: global.youtubeRefreshToken,
        ytChannelName: global.ytChannelName,
        ytAvatar: global.ytAvatar,
        ytChannelId: global.ytChannelId,             // NEW
        ytUploadsPlaylistId: global.ytUploadsPlaylistId, // NEW
        metaToken: global.metaToken,
        igAccountId: global.igAccountId,
        igUsername: global.igUsername,
        igName: global.igName,
        igAvatar: global.igAvatar,
        linkedinToken: global.linkedinToken,
        linkedinUserUrn: global.linkedinUserUrn,
        linkedinName: global.linkedinName,
        linkedinAvatar: global.linkedinAvatar
    };
    fs.writeFileSync(sessionPath, JSON.stringify(data, null, 2));
    console.log('[SESSION] Saved to disk.');
}

function loadSessions() {
    if (fs.existsSync(sessionPath)) {
        try {
            const data = JSON.parse(fs.readFileSync(sessionPath, 'utf8'));
            global.youtubeToken = data.youtubeToken;
            global.youtubeRefreshToken = data.youtubeRefreshToken;
            global.ytChannelName = data.ytChannelName;
            global.ytAvatar = data.ytAvatar;
            global.ytChannelId = data.ytChannelId;              // NEW
            global.ytUploadsPlaylistId = data.ytUploadsPlaylistId; // NEW
            global.metaToken = data.metaToken;
            global.igAccountId = data.igAccountId;
            global.igUsername = data.igUsername;
            global.igName = data.igName;
            global.igAvatar = data.igAvatar;
            global.linkedinToken = data.linkedinToken;
            global.linkedinUserUrn = data.linkedinUserUrn;
            global.linkedinName = data.linkedinName;
            global.linkedinAvatar = data.linkedinAvatar;
            console.log(`[SESSION] Loaded. YT Channel: ${global.ytChannelName || 'NONE'}, ID: ${global.ytChannelId || 'NONE'}, IG: ${global.igAccountId || 'NONE'}`);
        } catch (e) {
            console.error('[SESSION] Load failed:', e.message);
        }
    }
}

module.exports = { saveSessions, loadSessions };
