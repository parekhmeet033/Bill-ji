// Auth data layer: talks to the same endpoints the mobile app uses, so vendors
// sign in with the exact same credentials.
import { apiClient } from '../core/apiClient';

// POST /api/login → { status, token, data: user }
export async function loginRequest(email, password) {
  const res = await apiClient.post(
    'login',
    { email: email.trim(), password, device_type: 'web' },
    { auth: false },
  );
  return { token: res.token, user: res.data };
}

// POST /api/logout (best-effort; the token is also cleared locally).
export async function logoutRequest() {
  try {
    await apiClient.post('logout', {});
  } catch {
    /* ignore — local session is cleared regardless */
  }
}
