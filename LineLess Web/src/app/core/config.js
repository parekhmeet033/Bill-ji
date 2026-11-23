// Central configuration for the vendor web app.
//
// The API base URL defaults to the production backend (the same one the mobile
// app talks to). Override at build/dev time with VITE_API_BASE_URL in a .env
// file, e.g. VITE_API_BASE_URL=http://localhost:3000/api
export const API_BASE_URL =
  (import.meta.env && import.meta.env.VITE_API_BASE_URL) ||
  (typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? '/api'
    : 'https://lineless.goalscripture.in/api');

// Where product/category images are served from (mirrors the mobile app).
export const IMAGE_BASE_URL =
  (import.meta.env && import.meta.env.VITE_IMAGE_BASE_URL) ||
  'https://lineless.goalscripture.in/storage/products/';

// Raw Pusher-style WebSocket the backend broadcasts `dashboard.updated` on
// (the same one the mobile app uses for live updates).
export const WS_URL =
  (import.meta.env && import.meta.env.VITE_WS_URL) ||
  (typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.hostname}:3009`
    : 'wss://lineless.goalscripture.in');
