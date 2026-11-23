import { WS_URL } from './config';

// Singleton Pusher-style WebSocket client, mirroring the mobile ReverbService:
// connects, subscribes to the public `dashboard` channel, answers pings, and
// emits `dashboard.updated` events to subscribers. Auto-reconnects on drop.
let socket = null;
let shouldReconnect = true;
let reconnectTimer = null;
let refCount = 0;
const listeners = new Set();

function emit(evt) {
  listeners.forEach((fn) => { try { fn(evt); } catch { /* ignore */ } });
}

function handleMessage(raw) {
  let decoded;
  try { decoded = JSON.parse(raw); } catch { return; }
  const event = decoded.event;
  if (event === 'pusher:connection_established') {
    socket?.send(JSON.stringify({ event: 'pusher:subscribe', data: { channel: 'dashboard' } }));
  } else if (event === 'pusher:ping') {
    socket?.send(JSON.stringify({ event: 'pusher:pong' }));
  } else if (event) {
    // Normalize data (string or object) and emit to subscribers.
    let data = decoded.data;
    if (typeof data === 'string') { try { data = JSON.parse(data); } catch { /* keep string */ } }
    emit({ event, data });
  }
}

function connect() {
  if (socket && (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING)) return;
  shouldReconnect = true;
  try {
    socket = new WebSocket(WS_URL);
    socket.onmessage = (e) => handleMessage(e.data);
    socket.onclose = scheduleReconnect;
    socket.onerror = () => { try { socket?.close(); } catch { /* ignore */ } };
  } catch {
    scheduleReconnect();
  }
}

function scheduleReconnect() {
  socket = null;
  if (!shouldReconnect || refCount === 0) return;
  clearTimeout(reconnectTimer);
  reconnectTimer = setTimeout(connect, 5000);
}

function disconnect() {
  shouldReconnect = false;
  clearTimeout(reconnectTimer);
  try { socket?.close(); } catch { /* ignore */ }
  socket = null;
}

// Subscribe to realtime events; returns an unsubscribe function. The socket is
// opened on the first subscriber and closed when the last one leaves.
export function subscribeRealtime(onEvent) {
  listeners.add(onEvent);
  refCount += 1;
  connect();
  return () => {
    listeners.delete(onEvent);
    refCount -= 1;
    if (refCount <= 0) { refCount = 0; disconnect(); }
  };
}
