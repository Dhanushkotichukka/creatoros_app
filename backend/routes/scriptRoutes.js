const express = require('express');
const router = express.Router();
const scriptController = require('../controllers/scriptController');

router.post('/', scriptController.saveScript);
router.get('/', scriptController.getScripts);
router.put('/:id', scriptController.updateScript);
router.delete('/:id', scriptController.deleteScript);

module.exports = router;
