const express = require('express');
const path = require('path');
const rateLimit = require('express-rate-limit');
const cors = require('cors');

// Route Imports
const adminRoutes = require('./routes/adminRoutes');
const publicRoutes = require('./routes/publicRoutes');
const authRoutes = require('./routes/authRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const menuRoutes = require('./routes/menuRoutes');
const orderRoutes = require('./routes/orderRoutes');
const reportRoutes = require('./routes/reportRoutes');
const tableRoutes = require('./routes/tableRoutes');
const marketingRoutes = require('./routes/marketingRoutes');
const { pickLang } = require('./utils/i18n');

const app = express();

// ૧. Nginx રિવર્સ પ્રોક્સી સપોર્ટ (Rate Limit એરર અટકાવવા સૌથી ઉપર હોવું જરૂરી છે)
app.set('trust proxy', 1);

// CORS: allow the vendor web app (served from the marketing site / another
// origin) to call the JSON API from the browser. Credentials are carried in the
// Authorization header (Bearer token), not cookies, so a permissive origin with
// the needed headers is sufficient.
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Accept-Language', 'token'],
}));

// ૨. Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false
});
app.use(limiter);

// ૩. બોડી પાર્સિંગ
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Language detection: Accept-Language header → req.lang (en | hi | gu), default en.
// Used by responseFormatter to localize messages and by the menu repo for names.
app.use((req, res, next) => {
  req.lang = pickLang(req.headers['accept-language']);
  next();
});

// ૪. React વેબસાઇટના સ્ટેટિક ફાઇલ્સ (JS, CSS, SVGs, Favicon)
app.use('/website/dist', express.static(path.join(__dirname, '../website')));
app.use(express.static(path.join(__dirname, '../website')));

// ૫. અપલોડ્સ અને અન્ય સ્ટેટિક એસેટ્સ
app.use('/storage/products', express.static(path.join(__dirname, '../uploads/products')));
app.use('/uploads/categories', express.static(path.join(__dirname, '../uploads/categories')));
app.use('/assets', express.static(path.join(__dirname, '../uploads/assets')));

// ૬. હેલ્થ ચેક રાઉટ
app.get('/health', (req, res) => {
  res.status(200).json({ status: true, message: 'LineLess Backend is Healthy' });
});

// ૭. એડમિન રીડાયરેક્ટ: /admin અથવા /admin/ ખોલતાં જ સીધું લૉગિન પેજ પર જાય
app.get(['/admin', '/admin/'], (req, res) => {
  res.redirect('/admin/login');
});

// ૮. મુખ્ય વેબસાઇટ (React SPA) પેજીસ
app.get([
  '/', '/features', '/pricing', '/tutorial', '/about', '/contact', '/privacy-policy',
  '/login', '/app', '/app/*'
], (req, res) => {
  res.sendFile(path.join(__dirname, '../website/index.html'));
});

// ૯. વેબ એડમિન પેનલ (સર્વર-રેન્ડર્ડ HTML પેજીસ)
app.use('/', adminRoutes);

// ૧૦. પબ્લિક વેબ પેજીસ (મેન્યુ અને વેબ POS)
app.use('/', publicRoutes);

// ૧૧. બેકએન્ડ JSON API રાઉટ્સ
app.use('/api', authRoutes);
app.use('/api', dashboardRoutes);
app.use('/api', settingsRoutes);
app.use('/api', menuRoutes);
app.use('/api', orderRoutes);
app.use('/api', reportRoutes);
app.use('/api', tableRoutes);
app.use('/api', marketingRoutes);

// ૧૨. એરર હેન્ડલિંગ મિડલવેર (ઇનલાઇન હેન્ડલર)
const notFoundHandler = (req, res, next) => {
  res.status(404).json({
    status: false,
    success: false,
    message: `Route not found: ${req.method} ${req.originalUrl}`
  });
};

const errorHandler = (err, req, res, next) => {
  console.error('[SERVER ERROR]', err);
  res.status(err.status || 500).json({
    status: false,
    success: false,
    message: err.message || 'Internal Server Error'
  });
};

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;