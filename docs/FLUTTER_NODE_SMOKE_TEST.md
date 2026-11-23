# LineLess Flutter & Node.js E2E Smoke Test Report

This document records the end-to-end integration and smoke test results for the LineLess Flutter POS application connected to the Node.js Express + MySQL + Socket.IO backend (`http://66.116.241.221:3009/api/`).

---

## 1. Features Tested & Verification Status

| Feature / UI Flow | Target API / Service | Status | Notes / Response Verification |
| :--- | :--- | :--- | :--- |
| **1. Login** | `POST /api/login` | `PASSED` | Authenticates user; returns JWT token & user profile matching `UserModel.fromJson`. |
| **2. Dashboard** | `POST /api/dashboard` | `PASSED` | Fetches today's total/pending/completed/dispatched stats & recent orders matching `DashboardApiModel.fromJson`. |
| **3. Running Token** | `POST /api/dashboard` | `PASSED` | Returns highest active token number (`running_token`). |
| **4. Menu** | `POST /api/menu-list` | `PASSED` | Retrieves all product items matching `MenuItemApiModel.fromJson`. |
| **5. Categories** | `POST /api/category-list` | `PASSED` | Retrieves category list with product counts matching `CategoryModel.fromJson`. |
| **6. Add/Update/Delete Menu** | `POST /api/menu-add`, `menu-update`, `menu-destroy` | `PASSED` | Multipart image upload and CRUD operations verified. |
| **7. Menu Status** | `POST /api/menu-status` | `PASSED` | Toggles item availability (`0` = unavailable, `1` = available). |
| **8. Orders** | `POST /api/orders-list` | `PASSED` | Retrieves paginated order history with search and status/type filters. |
| **9. Order Status** | `POST /api/orders-status` | `PASSED` | Updates order status (`pending` -> `running` -> `completed` -> `dispatched`) and triggers real-time broadcast. |
| **10. POS / Walk-in Order** | `POST /api/save-table-order` | `PASSED` | Creates walk-in/counter POS orders with sequential token generation. |
| **11. Table Order** | `POST /api/save-table-order` | `PASSED` | Saves table cart sessions, item additions, and item removals. |
| **12. Pending Tables** | `POST /api/pending-tables` | `PASSED` | Fetches active unbilled table sessions matching `PendingTableModel.fromJson`. |
| **13. Settings** | `POST /api/settings` | `PASSED` | Retrieves and updates operating slot times, shop open status, and table count matching `ShopSettingsModel.fromJson`. |
| **14. Analytics / Reports** | `POST /api/reports-analytics` | `PASSED` | Requires report PIN if configured; returns revenue, sales, and payment breakdowns matching `ReportData.fromJson`. |
| **15. Logout** | `POST /api/logout` | `PASSED` | Clears device ID/session and invalidates auth token. |
| **16. Real-time Dashboard Update** | Socket.IO / Reverb WS | `PASSED` | Client subscribes to channel `dashboard` or room `shop_<id>`; receives `dashboard.updated` payload. |
| **17. KDS / Order Update** | Socket.IO / Reverb WS | `PASSED` | Triggered automatically on order creation and status change. |

---

## 2. Flutter Configuration

To switch the Flutter application to the Node.js backend (`66.116.241.221:3009`):

1. **`lib/core/constants/api_constants.dart`**:
   - `isNodeBackendDev = true`
   - `nodeServerHost = '66.116.241.221'`
   - Base URL: `http://66.116.241.221:3009/api/`
   - Web Base URL: `http://66.116.241.221:3009`
   - Products Image Base URL: `http://66.116.241.221:3009/storage/products/`
   - Category Image Base URL: `http://66.116.241.221:3009/uploads/categories/`
   - WebSocket URL: `ws://66.116.241.221:3009`
   - Production Laravel URLs preserved as fallback when `isNodeBackendDev = false`.

---

## 3. Real-time Status

- **Engine:** Socket.IO with Pusher/Reverb compatibility layer in Node.js backend (`src/config/socket.js`).
- **Connection:** Client establishes WebSocket connection, subscribes to channel `dashboard` or room `shop_<user_id>`.
- **Broadcast:** On order changes/creation, backend emits `dashboard.updated` payload:
  ```json
  {
    "event": "dashboard.updated",
    "data": { "user_id": "1" }
  }
  ```
- **Flutter Action:** `GlobalAlertProvider` receives event, triggers `fetchDashboard(isRealtime: true)`, plays alert tone, and sends new orders to thermal printer service.

---

## 4. Remaining Issues

- **None.**
