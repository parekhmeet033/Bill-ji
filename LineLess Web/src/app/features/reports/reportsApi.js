import { apiClient } from '../../core/apiClient';

// POST /api/reports-analytics → data: sales analytics (scoped to range when dates given).
// user_pin is required only if the vendor has set a reports PIN.
export async function fetchReports({ userPin = '', startDate = '', endDate = '' } = {}) {
  const body = {};
  if (userPin) body.user_pin = userPin;
  if (startDate) body.start_date = startDate;
  if (endDate) body.end_date = endDate;
  const res = await apiClient.post('reports-analytics', body);
  return res?.data ?? {};
}
