const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { syncDatabase } = require('./models');
const { loadSessions } = require('./utils/sessionHelper');

const path = require('path');
const fs = require('fs');
const crashLogPath = path.join(__dirname, 'crash_log.txt');

process.on('uncaughtException', (err) => {
    console.error('FATAL UNCAUGHT EXCEPTION:', err);
    fs.appendFileSync(crashLogPath, `[${new Date().toISOString()}] UNCAUGHT EXCEPTION: ${err.message}\n${err.stack}\n\n`);
});
process.on('unhandledRejection', (reason, promise) => {
    console.error('FATAL UNHANDLED REJECTION:', reason);
    fs.appendFileSync(crashLogPath, `[${new Date().toISOString()}] UNHANDLED REJECTION: ${reason}\n\n`);
});

const app = express();
const PORT = process.env.PORT || 3000;

// Load persistent sessions
global.youtubeToken = null;
global.metaToken = null;
global.linkedinToken = null;
loadSessions();

// Serve static uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Diagnostic middleware FIRST
app.use((req, res, next) => {
    console.log(`[REQUEST] ${req.method} ${req.url}`);
    next();
});

console.log('Initializing middleware...');
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Routes
const youtubeRoutes = require('./routes/youtubeRoutes');
const aiRoutes = require('./routes/aiRoutes');
const scriptRoutes = require('./routes/scriptRoutes');
const metaRoutes = require('./routes/metaRoutes');
const linkedinRoutes = require('./routes/linkedinRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const mediaRoutes = require('./routes/mediaRoutes');
const publishRoutes = require('./routes/publishRoutes');

console.log('Setting up routes...');
app.use('/auth/youtube', youtubeRoutes);
app.use('/api/ai/scripts', scriptRoutes);
app.use('/api/ai', aiRoutes);
app.use('/auth/meta', metaRoutes);
app.use('/auth/linkedin', linkedinRoutes); 
app.use('/api/publish', publishRoutes);
app.use('/auth/instagram', metaRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/media', mediaRoutes);

// Basic Route
app.get('/', (req, res) => {
    console.log('Handling base route /');
    res.json({ message: 'CreatorOS Backend API is running' });
});

console.log('Connecting to database...');
syncDatabase().then(() => {
    console.log('Starting server...');
    app.listen(PORT, () => {
        console.log(`Server is running on port ${PORT} (Listening on all interfaces)`);
        
        // Force the event loop to stay alive just in case something is prematurely closing the server handle
        setInterval(() => {}, 1000 * 60 * 60);
    });
}).catch(err => {
    console.error('Database sync failed:', err);
});
