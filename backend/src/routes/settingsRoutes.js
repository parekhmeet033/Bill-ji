const express = require('express');
const settingsController = require('../controllers/settingsController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/settings', authMiddleware, (req, res, next) => settingsController.handleSettings(req, res, next));

module.exports = router;
