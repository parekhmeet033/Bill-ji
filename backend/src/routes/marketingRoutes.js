const express = require('express');
const marketingController = require('../controllers/marketingController');

const router = express.Router();

// BillJi marketing website lead forms (public, no auth).
router.post('/book-demo', (req, res) => marketingController.bookDemo(req, res));
router.post('/contact', (req, res) => marketingController.contact(req, res));

module.exports = router;
