const logger = require('../utils/logger');
const { errorResponse } = require('../utils/responseFormatter');

function errorHandler(err, req, res, next) {
  logger.error(`Error on ${req.method} ${req.url}:`, err);

  const statusCode = err.statusCode || res.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  return errorResponse(res, message, statusCode < 400 ? 500 : statusCode);
}

function notFoundHandler(req, res, next) {
  return errorResponse(res, `Route not found: ${req.method} ${req.originalUrl}`, 404);
}

module.exports = {
  errorHandler,
  notFoundHandler
};
