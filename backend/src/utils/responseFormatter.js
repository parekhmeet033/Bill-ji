/**
 * Formats API responses to maintain 100% compatibility with Flutter ApiResponse models.
 */
const { translate } = require('./i18n');

// Request language is set by the Accept-Language middleware (defaults to 'en').
function langOf(res) {
  return (res && res.req && res.req.lang) || 'en';
}

function successResponse(res, message = 'Success', data = null, extra = {}) {
  const payload = {
    status: true,
    success: true,
    message: translate(langOf(res), message),
    ...extra
  };

  if (data !== null && data !== undefined) {
    payload.data = data;
  }

  return res.status(200).json(payload);
}

function errorResponse(res, message = 'An error occurred', statusCode = 400, errors = null) {
  const payload = {
    status: false,
    success: false,
    message: translate(langOf(res), message)
  };

  if (errors) {
    payload.errors = errors;
  }

  return res.status(statusCode).json(payload);
}

function paginatedResponse(res, message = 'Success', data = [], pagination = {}) {
  return res.status(200).json({
    status: true,
    success: true,
    message: translate(langOf(res), message),
    data,
    pagination: {
      current_page: pagination.currentPage || 1,
      last_page: pagination.lastPage || 1,
      per_page: pagination.perPage || 10,
      total: pagination.total || 0,
      next_page_url: pagination.nextPageUrl || null,
      prev_page_url: pagination.prevPageUrl || null
    }
  });
}

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse
};
