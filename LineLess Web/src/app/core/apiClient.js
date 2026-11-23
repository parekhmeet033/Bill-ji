// Thin HTTP client for the vendor web app (data layer).
//
// Clean-architecture note: feature "repositories" (e.g. dashboardApi.js) call
// this client; UI/presentation never touches fetch directly. The client owns
// base URL, auth header injection, JSON encoding, and uniform error handling.
import { API_BASE_URL } from './config';
import { getToken, clearSession } from '../auth/authStorage';

export class ApiError extends Error {
  constructor(message, status, data) {
    super(message || 'Request failed');
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

async function request(method, path, { body, auth = true, signal } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';

  if (auth) {
    const token = getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }

  let res;
  try {
    res = await fetch(`${API_BASE_URL}/${path.replace(/^\//, '')}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (networkErr) {
    throw new ApiError('Network error — check your connection.', 0, null);
  }

  let data = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  // Backend wraps responses as { status, success, message, data, ... }.
  const ok = res.ok && (data == null || data.status !== false);
  if (!ok) {
    // Auth expired/invalid → drop the session so the app redirects to /login.
    if (res.status === 401) clearSession();
    const message =
      (data && (data.message || data.error)) ||
      (res.status === 401 ? 'Session expired. Please sign in again.' : 'Request failed.');
    throw new ApiError(message, res.status, data);
  }

  return data;
}

// Multipart/form-data POST (for endpoints that accept an image upload). The
// browser sets the Content-Type with the correct boundary, so we don't set it.
async function postForm(path, formData, { auth = true } = {}) {
  const headers = { Accept: 'application/json' };
  if (auth) {
    const token = getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }
  let res;
  try {
    res = await fetch(`${API_BASE_URL}/${path.replace(/^\//, '')}`, { method: 'POST', headers, body: formData });
  } catch {
    throw new ApiError('Network error — check your connection.', 0, null);
  }
  let data = null;
  const text = await res.text();
  if (text) { try { data = JSON.parse(text); } catch { data = text; } }
  const ok = res.ok && (data == null || data.status !== false);
  if (!ok) {
    if (res.status === 401) clearSession();
    throw new ApiError((data && (data.message || data.error)) || 'Upload failed.', res.status, data);
  }
  return data;
}

export const apiClient = {
  get: (path, opts) => request('GET', path, opts),
  post: (path, body, opts) => request('POST', path, { ...opts, body }),
  put: (path, body, opts) => request('PUT', path, { ...opts, body }),
  patch: (path, body, opts) => request('PATCH', path, { ...opts, body }),
  del: (path, opts) => request('DELETE', path, opts),
  postForm,
};
