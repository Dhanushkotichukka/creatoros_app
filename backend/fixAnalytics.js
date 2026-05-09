const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'routes', 'analyticsRoutes.js');
let code = fs.readFileSync(filePath, 'utf8');

// 1. Replace the getYTAnalyticsData helper to accept userId
code = code.replace(
    /const getYTAnalyticsData = async \(type = 'overview', days = 28\) => {[\s\S]*?const analytics = await youtubeController\.getYouTubeAnalyticsClient\(\);/m,
    `const getYTAnalyticsData = async (userId, type = 'overview', days = 28) => {
    try {
        const analytics = await youtubeController.getYouTubeAnalyticsClient(userId);`
);

// 2. Replace all calls to getYTAnalyticsData to pass req.user.id
code = code.replace(/getYTAnalyticsData\('([^']+)',\s*(\d+)\)/g, "getYTAnalyticsData(req.user.id, '$1', $2)");
code = code.replace(/getYTAnalyticsData\('([^']+)'\)/g, "getYTAnalyticsData(req.user.id, '$1')");

// 3. Replace all calls to getYouTubeClient() to pass req.user.id
code = code.replace(/youtubeController\.getYouTubeClient\(\)/g, "youtubeController.getYouTubeClient(req.user.id)");

// 4. Replace all occurrences of global. with req.platformContext.
code = code.replace(/global\./g, 'req.platformContext.');

// 5. Inject the context building middleware at the top of the file
const contextMiddleware = `
const Token = require('../models/Token');

// Middleware to inject platform context per user request
router.use(async (req, res, next) => {
    if (!req.user || !req.user.id) return next();
    const tokens = await Token.find({ userId: req.user.id });
    req.platformContext = {};
    for (const t of tokens) {
        if (t.platform === 'youtube') {
            req.platformContext.youtubeToken = t.accessToken;
            req.platformContext.ytChannelId = t.platformAccountId;
            req.platformContext.ytChannelName = t.platformAccountName;
            req.platformContext.ytAvatar = t.avatar;
        } else if (t.platform === 'meta') {
            req.platformContext.metaToken = t.accessToken;
            req.platformContext.igAccountId = t.platformAccountId;
            req.platformContext.igName = t.platformAccountName;
            req.platformContext.igUsername = t.platformAccountName;
            req.platformContext.igAvatar = t.avatar;
        } else if (t.platform === 'linkedin') {
            req.platformContext.linkedinToken = t.accessToken;
            req.platformContext.linkedinName = t.platformAccountName;
            req.platformContext.linkedinAvatar = t.avatar;
        }
    }
    next();
});
`;

code = code.replace(/const router = express\.Router\(\);\s*/, "const router = express.Router();\n" + contextMiddleware);

fs.writeFileSync(filePath, code);
console.log('Successfully patched analyticsRoutes.js!');
