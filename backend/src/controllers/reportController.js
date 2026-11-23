const reportService = require('../services/reportService');
const { successResponse, errorResponse } = require('../utils/responseFormatter');

class ReportController {
  async getReportsAnalytics(req, res, next) {
    try {
      const { user_pin, start_date, end_date } = req.body;
      const data = await reportService.getReportsAnalytics(req.user.id, user_pin, {
        startDate: start_date || null,
        endDate: end_date || null,
      });
      return successResponse(res, 'Analytics fetched', data);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch analytics', 400);
    }
  }
}

module.exports = new ReportController();
