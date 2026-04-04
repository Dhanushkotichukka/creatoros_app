const express = require('express');
const router = express.Router();
const publishController = require('../controllers/publishController');

router.post('/', publishController.publishToAll);

module.exports = router;
