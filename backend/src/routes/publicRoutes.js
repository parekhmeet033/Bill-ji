const express = require('express');
const publicController = require('../controllers/publicController');

const router = express.Router();

// Relax CSP for these public HTML pages (CDN assets + inline scripts).
router.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net",
      "font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net",
      "img-src 'self' data: https: http:",
      "connect-src 'self'"
    ].join('; ')
  );
  next();
});

// Privacy policy pages
router.get('/privacy-policy', (req, res) => publicController.privacyPage(req, res));
router.get('/privacy', (req, res) => publicController.privacyPage(req, res));

// JSON data
router.get('/public-api/shop/:slug', (req, res) => publicController.shopData(req, res));
router.post('/public-api/pos/:slug/order', (req, res) => publicController.submitOrder(req, res));
router.post('/public-api/menu/:slug/order', (req, res) => publicController.submitMenuOrder(req, res));

// Order status, cancel, and edit endpoints
router.get('/public-api/order/:orderId', (req, res) => publicController.getOrderStatus(req, res));
router.post('/public-api/order/:orderId/cancel', (req, res) => publicController.cancelOrder(req, res));
router.post('/public-api/order/:orderId/edit', (req, res) => publicController.editOrder(req, res));

// Customer menu page: /menu/:slug
router.get('/menu/:slug', (req, res) => publicController.menuPage(req, res));

// Web POS page: /:code/pos-order/:slug
router.get('/:code/pos-order/:slug', (req, res) => publicController.posPage(req, res));

module.exports = router;
