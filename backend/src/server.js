const http = require('http');
const path = require('path');
const dotenv = require('dotenv');

// Explicitly load .env relative to server.js directory
dotenv.config({ path: path.join(__dirname, '../.env') });

const app = require('./app');
const { initDatabase } = require('./config/database');
const { initSocket } = require('./config/socket');
const logger = require('./utils/logger');

const PORT = process.env.PORT || 3009;
const HOST = process.env.HOST || '0.0.0.0';

const server = http.createServer(app);

// Initialize Socket.IO
initSocket(server);

// Start Server immediately so Express & Health checks are active
server.listen(PORT, HOST, () => {
  logger.info(`==================================================`);
  logger.info(`BillJi Node.js Backend Server running on http://${HOST}:${PORT}`);
  logger.info(`Local Endpoint: http://localhost:${PORT}/api/`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`Socket.IO Real-time Engine Ready`);
  logger.info(`==================================================`);
});

// Initialize Database Connection and Schema asynchronously
initDatabase()
  .then(() => {
    logger.info(`[DATABASE] Database & Schema Ready`);
  })
  .catch((err) => {
    logger.error(`[DATABASE ERROR] Database initialization error:`, err);
  });

// Graceful Shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received. Closing HTTP server...');
  server.close(() => {
    logger.info('HTTP server closed.');
    process.exit(0);
  });
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', reason);
});
