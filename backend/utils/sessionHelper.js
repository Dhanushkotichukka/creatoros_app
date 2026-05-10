// sessionHelper.js — retired.
// Platform tokens are now stored per-user in MongoDB (Token collection).
// This file is kept as a no-op stub so existing imports don't break.

// Refactored to not use global variables
async function saveSessions() {
    // Session state should now be in MongoDB
}

async function loadSessions() {
    // Session state should now be in MongoDB
}

module.exports = { saveSessions, loadSessions };
