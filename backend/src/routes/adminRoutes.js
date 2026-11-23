const express = require('express');
const adminController = require('../controllers/adminController');
const { requireAdminPage, requireAdminApi } = require('../middleware/adminAuthMiddleware');

const router = express.Router();

// Relax CSP for the admin panel only (CDN assets + inline scripts).
// The strict helmet policy still applies to the rest of the app.
router.use((req, res, next) => {
  res.setHeader(
    'Content-Security-Policy',
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net",
      "font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net",
      "img-src 'self' data: https:",
      "connect-src 'self'"
    ].join('; ')
  );
  next();
});

// ---- Pages ----
router.get('/admin', requireAdminPage, (req, res) => res.redirect('/admin/dashboard'));
router.get('/admin/login', (req, res) => adminController.loginPage(req, res));
router.post('/admin/login', (req, res) => adminController.login(req, res));
router.get('/admin/logout', (req, res) => adminController.logout(req, res));
router.get('/admin/dashboard', requireAdminPage, (req, res) => adminController.dashboardPage(req, res));
router.get('/admin/users', requireAdminPage, (req, res) => adminController.usersPage(req, res));

// ---- JSON API (same-origin, cookie-protected) ----
router.get('/admin/api/me', requireAdminApi, (req, res) => adminController.me(req, res));
router.get('/admin/api/dashboard', requireAdminApi, (req, res) => adminController.dashboardData(req, res));
router.get('/admin/api/users', requireAdminApi, (req, res) => adminController.listUsers(req, res));
router.post('/admin/api/users', requireAdminApi, (req, res) => adminController.createUser(req, res));
router.put('/admin/api/users/:id', requireAdminApi, (req, res) => adminController.updateUser(req, res));
router.delete('/admin/api/users/:id', requireAdminApi, (req, res) => adminController.deleteUser(req, res));

module.exports = router;
