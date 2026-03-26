const fs = require('fs');
const path = require('path');

const sessionPath = path.join(__dirname, '..', 'session_store.json');

function saveSessions() {
    const data = {
        youtubeToken: global.youtubeToken,
        ytChannelName: global.ytChannelName,
        ytAvatar: global.ytAvatar,
        metaToken: global.metaToken,
        igAccountId: global.igAccountId,
        igUsername: global.igUsername,
        igName: global.igName,
        igAvatar: global.igAvatar,
        linkedinToken: global.linkedinToken
    };
    fs.writeFileSync(sessionPath, JSON.stringify(data, null, 2));
    console.log('[SESSION] Saved to disk.');
}

function loadSessions() {
    if (fs.existsSync(sessionPath)) {
        try {
            const data = JSON.parse(fs.readFileSync(sessionPath, 'utf8'));
            global.youtubeToken = data.youtubeToken;
            global.ytChannelName = data.ytChannelName;
            global.ytAvatar = data.ytAvatar;
            global.metaToken = data.metaToken;
            global.igAccountId = data.igAccountId;
            global.igUsername = data.igUsername;
            global.igName = data.igName;
            global.igAvatar = data.igAvatar;
            global.linkedinToken = data.linkedinToken;
            console.log(`[SESSION] Loaded from disk. IG ID: ${global.igAccountId || 'NONE'}, Meta Token: ${global.metaToken ? 'EXISTS' : 'NONE'}`);
        } catch (e) {
            console.error('[SESSION] Load failed:', e.message);
        }
    }
}

module.exports = { saveSessions, loadSessions };
