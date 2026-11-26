const tableService = require('../services/tableService');
const { successResponse, errorResponse } = require('../utils/responseFormatter');

class TableController {
  async getPendingTables(req, res, next) {
    try {
      const data = await tableService.getPendingTables(req.user.id);
      return successResponse(res, 'Pending tables fetched', data);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch pending tables', 400);
    }
  }

  async saveTableOrder(req, res, next) {
    try {
      const result = await tableService.saveTableOrder(req.user.id, req.body);
      return successResponse(res, 'Table order saved', result);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to save table order', 400);
    }
  }

  async cancelTableOrder(req, res, next) {
    try {
      const { table_no } = req.body;
      if (!table_no) {
        return errorResponse(res, 'table_no is required', 400);
      }
      const result = await tableService.cancelTableOrder(req.user.id, table_no);
      return successResponse(res, 'Table order cancelled successfully', result);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to cancel table order', 400);
    }
  }
}

module.exports = new TableController();
