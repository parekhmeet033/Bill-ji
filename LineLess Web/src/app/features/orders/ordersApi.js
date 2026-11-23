import { apiClient } from '../../core/apiClient';

// POST /api/orders-list → { data: orders, pagination: { currentPage, lastPage, perPage, total } }
export async function fetchOrders({ status = 'All', orderType = 'All', search = '', startDate = '', endDate = '', page = 1 } = {}) {
  const res = await apiClient.post('orders-list', {
    status,
    order_type: orderType,
    search,
    start_date: startDate,
    end_date: endDate,
    page,
  });
  return {
    orders: res?.data ?? [],
    pagination: res?.pagination ?? { currentPage: page, lastPage: 1, total: 0 },
  };
}

// POST /api/orders-status → advance an order's status.
export async function updateOrderStatus(orderId, status, extra = {}) {
  return apiClient.post('orders-status', { order_id: orderId, status, ...extra });
}

// GET /api/orders → recent orders (up to 100), used for distribution charts.
export async function fetchAllOrders() {
  const res = await apiClient.get('orders');
  return res?.data ?? [];
}
