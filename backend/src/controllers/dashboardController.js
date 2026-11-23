const dashboardService = require('../services/dashboardService');
const { successResponse, errorResponse } = require('../utils/responseFormatter');

class DashboardController {
  async getDashboardData(req, res, next) {
    try {
      const userId = req.user.id;
      const data = await dashboardService.getDashboardData(userId);
      return successResponse(res, 'Dashboard data fetched', data);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch dashboard data', 400);
    }
  }
}

module.exports = new DashboardController();
