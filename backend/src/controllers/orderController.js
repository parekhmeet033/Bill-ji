const orderService = require('../services/orderService');
const { paginatedResponse, successResponse, errorResponse } = require('../utils/responseFormatter');

class OrderController {
  async getOrdersList(req, res, next) {
    try {
      const { status, order_type, search, start_date, end_date, page } = req.body;
      const filters = {
        status,
        orderType: order_type,
        search,
        startDate: start_date,
        endDate: end_date,
        page: parseInt(page || '1', 10)
      };

      const result = await orderService.getOrdersList(req.user.id, filters);
      return paginatedResponse(res, 'Orders fetched', result.data, result.pagination);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch orders list', 400);
    }
  }

  async getAllOrders(req, res, next) {
    try {
      const data = await orderService.getAllOrders(req.user.id);
      return successResponse(res, 'Orders fetched', data);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch orders', 400);
    }
  }

  async updateOrderStatus(req, res, next) {
    try {
      const { order_id, status, payment_type, upi_amount, cash_amount } = req.body;
      if (!order_id || !status) {
        return errorResponse(res, 'order_id and status are required', 400);
      }

      await orderService.updateOrderStatus(req.user.id, order_id, status, payment_type, upi_amount, cash_amount);
      return successResponse(res, 'Order status updated successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to update order status', 400);
    }
  }

  async deleteOrders(req, res, next) {
    try {
      const { start_date, end_date } = req.body;
      if (!start_date || !end_date) {
        return errorResponse(res, 'start_date and end_date are required', 400);
      }

      await orderService.deleteOrders(req.user.id, start_date, end_date);
      return successResponse(res, 'Orders deleted successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to delete orders', 400);
    }
  }

  async createPosOrder(req, res, next) {
    try {
      const { items } = req.body;
      if (!Array.isArray(items) || items.length === 0) {
        return errorResponse(res, 'At least one item is required', 400);
      }
      // The normal POS endpoint always finalizes (places) the order; it never
      // creates/keeps a draft, even if the client sends order_status.
      const result = await orderService.createPosOrder(req.user.id, { ...req.body, order_status: 'pending' });
      return successResponse(res, 'Order placed successfully', {
        order_id: result.orderId,
        token_no: result.tokenNo,
        total: result.total
      });
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to place order', 400);
    }
  }

  // Upserts the in-progress take-away draft (auto-saved POS cart). Separate from
  // createPosOrder so an auto-save can never be mistaken for a placed order.
  async savePosDraft(req, res, next) {
    try {
      const { items } = req.body;
      if (!Array.isArray(items) || items.length === 0) {
        return errorResponse(res, 'At least one item is required', 400);
      }
      const result = await orderService.createPosOrder(req.user.id, { ...req.body, order_status: 'draft' });
      return successResponse(res, 'Draft saved', {
        order_id: result.orderId,
        draft: true
      });
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to save draft', 400);
    }
  }

  // Returns the user's in-progress take-away draft (auto-saved POS cart), or
  // null, so the POS screen can restore it after an app/device restart.
  async getPosDraft(req, res, next) {
    try {
      const draft = await orderService.getDraftPosOrder(req.user.id);
      return successResponse(res, 'Draft fetched', { order: draft });
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch draft', 400);
    }
  }

  // Discards the in-progress take-away draft (POS order cancelled).
  async clearPosDraft(req, res, next) {
    try {
      const cleared = await orderService.clearDraftPosOrder(req.user.id);
      return successResponse(res, 'Draft cleared', { cleared });
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to clear draft', 400);
    }
  }
}

module.exports = new OrderController();
