const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { syncDatabase } = require('./models');
const { loadSessions } = require('./utils/sessionHelper');

const path = require('path');
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
const metaRoutes = require('./routes/metaRoutes');
const linkedinRoutes = require('./routes/linkedinRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const mediaRoutes = require('./routes/mediaRoutes');

console.log('Setting up routes...');
app.use('/auth/youtube', youtubeRoutes);
app.use('/api/ai', aiRoutes);
app.use('/auth/meta', metaRoutes);
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
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`Server is running on port ${PORT} (0.0.0.0)`);
    });
}).catch(err => {
    console.error('Database sync failed:', err);
});
