const express = require('express');
const tableController = require('../controllers/tableController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/pending-tables', authMiddleware, (req, res, next) => tableController.getPendingTables(req, res, next));
router.post('/save-table-order', authMiddleware, (req, res, next) => tableController.saveTableOrder(req, res, next));
router.post('/cancel-table-order', authMiddleware, (req, res, next) => tableController.cancelTableOrder(req, res, next));

module.exports = router;
