const { verifyToken } = require('../utils/tokenGenerator');

const COOKIE_NAME = 'admin_token';

// Minimal cookie parser (no cookie-parser dependency needed).
function parseCookies(req) {
  const header = req.headers.cookie;
  const out = {};
  if (!header) return out;
  header.split(';').forEach((pair) => {
    const idx = pair.indexOf('=');
    if (idx === -1) return;
    const key = pair.slice(0, idx).trim();
    const val = pair.slice(idx + 1).trim();
    out[key] = decodeURIComponent(val);
  });
  return out;
}

function getAdminFromRequest(req) {
  const token = parseCookies(req)[COOKIE_NAME];
  if (!token) return null;
  return verifyToken(token); // { id, email, role } or null
}

// Gate for HTML pages: redirect to login when not authenticated.
function requireAdminPage(req, res, next) {
  const admin = getAdminFromRequest(req);
  if (!admin) return res.redirect('/admin/login');
  req.admin = admin;
  next();
}

// Gate for JSON API: respond 401 when not authenticated.
function requireAdminApi(req, res, next) {
  const admin = getAdminFromRequest(req);
  if (!admin) {
    return res.status(401).json({ status: false, success: false, message: 'Not authenticated' });
  }
  req.admin = admin;
  next();
}

module.exports = { COOKIE_NAME, requireAdminPage, requireAdminApi, getAdminFromRequest };
