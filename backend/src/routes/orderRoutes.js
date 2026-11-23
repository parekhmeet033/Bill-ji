const express = require('express');
const orderController = require('../controllers/orderController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/orders-list', authMiddleware, (req, res, next) => orderController.getOrdersList(req, res, next));
router.get('/orders', authMiddleware, (req, res, next) => orderController.getAllOrders(req, res, next));
router.post('/orders-status', authMiddleware, (req, res, next) => orderController.updateOrderStatus(req, res, next));
router.post('/pos-order', authMiddleware, (req, res, next) => orderController.createPosOrder(req, res, next));
router.post('/pos-draft-save', authMiddleware, (req, res, next) => orderController.savePosDraft(req, res, next));
router.post('/pos-draft', authMiddleware, (req, res, next) => orderController.getPosDraft(req, res, next));
router.post('/pos-draft-clear', authMiddleware, (req, res, next) => orderController.clearPosDraft(req, res, next));
router.post('/orders-deleted', authMiddleware, (req, res, next) => orderController.deleteOrders(req, res, next));

module.exports = router;
