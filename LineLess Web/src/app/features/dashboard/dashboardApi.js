import { apiClient } from '../../core/apiClient';

// POST /api/dashboard → today's stats, running token, and recent orders.
// Returns the normalized data object (the backend wraps it under `data`).
export async function fetchDashboard() {
  const res = await apiClient.post('dashboard', {});
  return res?.data ?? res ?? {};
}

// POST /api/orders-status → advance an order's status.
export async function updateOrderStatus(orderId, status, extra = {}) {
  return apiClient.post('orders-status', { order_id: orderId, status, ...extra });
}
