// sessionHelper.js — retired.
// Platform tokens are now stored per-user in MongoDB (Token collection).
// This file is kept as a no-op stub so existing imports don't break.

function saveSessions() {
    // No-op: tokens are persisted in MongoDB
}

function loadSessions() {
    // No-op: tokens are loaded from MongoDB on demand
}

module.exports = { saveSessions, loadSessions };
