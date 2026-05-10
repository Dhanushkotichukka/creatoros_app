const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { syncDatabase } = require('./models');

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

// Initialize session helpers if needed, but globals are removed
// loadSessions();

// Serve static uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Diagnostic middleware FIRST
app.use((req, res, next) => {
    console.log(`[REQUEST] ${req.method} ${req.url}`);
    next();
});

console.log('Initializing middleware...');

const ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:8080',
    process.env.FRONTEND_WEB_URL,
    process.env.RENDER_EXTERNAL_URL
].filter(Boolean);

app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps or Postman)
        if (!origin || ALLOWED_ORIGINS.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error(`CORS policy: Origin '${origin}' is not allowed`));
        }
    },
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

// Auth
const authRoutes = require('./routes/authRoutes');
const authenticateToken = require('./middleware/authMiddleware');

console.log('Setting up routes...');

// Auth routes (public)
app.use('/auth/google-signin', authRoutes);

// Protected routes
app.use('/api/ai/scripts', authenticateToken, scriptRoutes);
app.use('/api/ai', authenticateToken, aiRoutes);
app.use('/api/publish', authenticateToken, publishRoutes);
app.use('/api/analytics', authenticateToken, analyticsRoutes);
app.use('/api/media', authenticateToken, mediaRoutes);

// Platform OAuth routes stay PUBLIC
app.use('/auth/youtube', youtubeRoutes);
app.use('/auth/meta', metaRoutes);
app.use('/auth/linkedin', linkedinRoutes);
app.use('/auth/instagram', metaRoutes);

// Basic Route
app.get('/', (req, res) => {
    console.log('Handling base route /');
    res.json({ message: 'CreatorOS Backend API is running' });
});

const schedulerService = require('./services/schedulerService');

console.log('Connecting to database...');
syncDatabase().then(() => {
    console.log('Starting server...');
    schedulerService.start();
    app.listen(PORT, () => {
        console.log(`Server is running on port ${PORT} (Listening on all interfaces)`);
        setInterval(() => {}, 1000 * 60 * 60);
    });
}).catch(err => {
    console.error('Database connection failed:', err);
});
