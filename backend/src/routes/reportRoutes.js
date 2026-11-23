const express = require('express');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/reports-analytics', authMiddleware, (req, res, next) => reportController.getReportsAnalytics(req, res, next));

module.exports = router;
