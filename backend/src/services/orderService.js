const orderRepository = require('../repositories/orderRepository');
const { emitDashboardUpdate } = require('../config/socket');

class OrderService {
  async getOrdersList(userId, filters) {
    return await orderRepository.getOrdersList(userId, filters);
  }

  async getAllOrders(userId) {
    return await orderRepository.getAllOrdersRaw(userId);
  }

  async updateOrderStatus(userId, orderId, status, paymentType, upiAmount, cashAmount) {
    const success = await orderRepository.updateOrderStatus(userId, orderId, status, paymentType, upiAmount, cashAmount);
    if (success) {
      // Trigger Socket.IO real-time update
      emitDashboardUpdate(userId);
    }
    return success;
  }

  async deleteOrders(userId, startDate, endDate) {
    await orderRepository.deleteOrdersByDate(userId, startDate, endDate);
    emitDashboardUpdate(userId);
    return true;
  }

  // In-app POS: create a takeaway order that enters the normal workflow (pending).
  async createPosOrder(userId, data) {
    // 'draft' = the in-progress POS cart auto-saved before the order is placed;
    // 'pending' = the order is actually placed.
    const status = (data.order_status || 'pending').toLowerCase() === 'draft' ? 'draft' : 'pending';
    const result = await orderRepository.createDirectOrder(userId, {
      customer_name: data.customer_name,
      customer_mobile: data.customer_mobile,
      special_note: data.special_note,
      order_type: 'takeaway',
      order_status: status,
      payment_type: data.payment_type || null,
      upi_amount: data.upi_amount != null ? data.upi_amount : null,
      cash_amount: data.cash_amount != null ? data.cash_amount : null,
      items: data.items || []
    });
    // Drafts are hidden from the dashboard/kitchen, so don't churn realtime on
    // every keystroke; only a placed order triggers a refresh.
    if (status !== 'draft') emitDashboardUpdate(userId);
    return result;
  }

  async getDraftPosOrder(userId) {
    return await orderRepository.getDraftPosOrder(userId);
  }

  async clearDraftPosOrder(userId) {
    return await orderRepository.clearDraftPosOrder(userId);
  }
}

module.exports = new OrderService();
