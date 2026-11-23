# LineLess Real-time Communication Specification (Socket.IO)

This document details the real-time WebSocket infrastructure built with Node.js and Socket.IO to replace Laravel Reverb.

---

## 1. Socket.IO Connection Details

- **URL:** `ws://localhost:3009` (or `wss://lineless.goalscripture.in`)
- **Transports:** `['websocket', 'polling']`

---

## 2. Authentication & Room Isolation

To isolate real-time events between restaurants, Socket.IO uses Shop Rooms (`shop_<user_id>`).

### Method 1: Emit `authenticate` Event
Upon connection, client sends:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsIn..."
}
```
The server validates the JWT token, extracts `user.id` (e.g. `1`), and joins room `shop_1`.

### Method 2: Emit `join_shop` Event
Client sends:
```json
1
```
The server joins room `shop_1`.

### Method 3: Legacy Pusher/Reverb Subscription (`pusher:subscribe`)
For full backward compatibility with the existing Reverb service:
Client sends:
```json
{
  "event": "pusher:subscribe",
  "data": { "channel": "dashboard" }
}
```
The server joins channel room `dashboard`.

---

## 3. Real-time Events & Payload Format

### Event: `dashboard.updated`

#### When Emitted:
- When a new order is placed / saved (`/api/save-table-order`).
- When an order status is updated (`/api/orders-status`).
- When orders are deleted (`/api/orders-deleted`).

#### Payload:
```json
{
  "event": "dashboard.updated",
  "data": {
    "user_id": "1"
  }
}
```

#### Consumer in Flutter Application:
- **Consumer:** `lib/providers/global_alert_provider.dart`
- **Listener:** `_reverbService.eventStream`
- **Actions Triggered:**
  1. Checks if `data.user_id` matches current logged-in user.
  2. Calls `orderProvider.fetchDashboard(isRealtime: true)`.
  3. Plays sound notification (`_playMultiAlert`).
  4. Enqueues new orders to `PrinterService` for thermal printing.
