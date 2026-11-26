import { apiClient } from '../../core/apiClient';

// POST /api/pending-tables → data: active dine-in tables (table_no, customer_name, total_amount, items[]).
export async function fetchPendingTables() {
  const res = await apiClient.post('pending-tables', {});
  return res?.data ?? [];
}

// POST /api/table-product-list → data: categories (each with products[]) — the POS catalogue.
export async function fetchTableProducts() {
  const res = await apiClient.post('table-product-list', {});
  return res?.data ?? [];
}

// POST /api/save-table-order → upserts a dine-in table order (status 'pending'
// to auto-save, 'completed' to finalize). Returns the saved order summary.
export async function saveTableOrder(payload) {
  const res = await apiClient.post('save-table-order', payload);
  return res?.data ?? res ?? {};
}

// POST /api/pos-order → places a takeaway order and returns { order_id, token_no }.
export async function placePosOrder({ customerName, customerMobile, note, total, paymentType, upiAmount, cashAmount, items }) {
  const res = await apiClient.post('pos-order', {
    customer_name: customerName || '',
    customer_mobile: customerMobile || '',
    special_note: note || '',
    total_amount: total,
    payment_type: paymentType || null,
    upi_amount: upiAmount ?? null,
    cash_amount: cashAmount ?? null,
    items,
  });
  return res?.data ?? res ?? {};
}

// POST /api/cancel-table-order → cancels active dine-in table order and frees the table
export async function cancelTableOrder(tableNo) {
  const res = await apiClient.post('cancel-table-order', { table_no: Number(tableNo) });
  return res?.data ?? res ?? {};
}

// POST /api/pos-draft-clear → clears any saved takeaway POS draft
export async function clearPosDraft() {
  try {
    const res = await apiClient.post('pos-draft-clear', {});
    return res?.data ?? res ?? {};
  } catch {
    return {};
  }
}
