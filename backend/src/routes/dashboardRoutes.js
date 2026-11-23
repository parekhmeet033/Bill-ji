const express = require('express');
const dashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/dashboard', authMiddleware, (req, res, next) => dashboardController.getDashboardData(req, res, next));

module.exports = router;
