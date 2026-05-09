const fs = require('fs');
const path = require('path');

const sessionPath = path.join(__dirname, '..', 'session_store.json');

// Refactored to not use global variables
async function saveSessions() {
    // Session state should now be in MongoDB
}

async function loadSessions() {
    // Session state should now be in MongoDB
}

module.exports = { saveSessions, loadSessions };
