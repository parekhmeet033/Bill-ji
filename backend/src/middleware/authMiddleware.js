const { verifyToken } = require('../utils/tokenGenerator');
const { errorResponse } = require('../utils/responseFormatter');

function authMiddleware(req, res, next) {
  let token = null;

  // Check Authorization header
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.substring(7);
  } else if (req.headers['token']) {
    token = req.headers['token'];
  }

  if (!token) {
    return errorResponse(res, 'Authentication token missing', 401);
  }

  const decoded = verifyToken(token);
  if (!decoded) {
    return errorResponse(res, 'Token expired or invalid', 401);
  }

  req.user = decoded; // { id, email, role }
  next();
}

module.exports = authMiddleware;
