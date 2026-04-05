const linkedinController = require('./controllers/linkedinController');
const path = require('path');
const fs = require('fs');

global.linkedinToken = process.env.LINKEDIN_TOKEN; // Wait, I need a token!
