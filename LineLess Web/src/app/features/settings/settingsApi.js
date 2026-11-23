import { apiClient } from '../../core/apiClient';

// POST /api/settings { type: 'get' } → data: shop settings.
export async function fetchSettings() {
  const res = await apiClient.post('settings', { type: 'get' });
  return res?.data ?? {};
}

// POST /api/settings with fields → updates (no `type` means update).
export async function saveSettings(payload) {
  const res = await apiClient.post('settings', payload);
  return res?.data ?? {};
}
