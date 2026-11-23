# Flutter ↔ Node.js Integration Report

Audit of the Flutter app against the Node.js backend now running on the recovered
Laravel `lineless` database (source of truth). **No speculative changes were made.**
Every Flutter endpoint, model, status value, and the realtime path were verified; only
items that would actually break a flow are flagged.

Backend base (physical device): `http://192.168.1.3:3009/api/` · WS: `ws://192.168.1.3:3009`

---

## A. API compatibility table
All 23 Flutter `ApiConstants` endpoints resolve to a Node route (method/path verified).

| Flutter endpoint | Method | Node route | Status |
|---|---|---|---|
| login | POST | /api/login | ✅ |
| logout | POST | /api/logout | ✅ |
| dashboard | POST | /api/dashboard | ✅ |
| menu-list | POST | /api/menu-list | ✅ |
| menu-add / menu-update / menu-destroy / menu-status / menu-reorder | POST | same | ✅ |
| category-list / category-add / category-update / category-destroy / category-reorder | POST | same | ✅ |
| table-product-list | POST | /api/table-product-list | ✅ |
| orders-list | POST | /api/orders-list | ✅ |
| orders-status | POST | /api/orders-status | ✅ |
| save-table-order | POST | /api/save-table-order | ✅ |
| pos-order | POST | /api/pos-order | ✅ |
| pending-tables | POST | /api/pending-tables | ✅ |
| reports-analytics | POST | /api/reports-analytics | ✅ |
| settings | POST | /api/settings | ✅ |
| forgot-pin | POST | /api/forgot-pin | ✅ |

No missing or orphaned endpoints. All requests are JSON `POST`.

## B. Flutter model compatibility
| Response | Flutter parser | Item keys expected | Node keys returned | Status |
|---|---|---|---|---|
| dashboard.recent_orders | `OrderApiModel.fromDashboardJson` | order_id, token_no, order_date, product_name, quantity, total | same | ✅ |
| orders-list | `OrderApiModel.fromDashboardJson` | same as above | same | ✅ |
| /orders (getOrders) | `OrderApiModel.fromJson` | id, token_number, created_at, name | same (`getAllOrdersRaw`) | ✅ |
| login | `UserModel.fromJson` | id, name, email, phone, role, profile_image | same | ✅ |
| pending-tables | `PendingTableModel` | table_no, customer_name, customer_mobile, order_note, total_amount, items[qty,price,total,unit,product_name,created_at] | same | ✅ |
| settings | `ShopSettingsModel` | shop_open, category_display (int **or** string accepted), times, opration_mode_status, number_of_tables, generated_code | restaurant_settings row | ✅ |
| reports | `ReportData` | revenue/sales/counts | same | ✅ |
| menu/category | menu/category models | id, name, price, half_price, image, status, sort_order, category_id, products_count | same | ✅ |

Key mappings handled server-side (Laravel → Flutter field name preserved): `status` (enum)→`status`, `qty`→`quantity`, `order_note`→`special_note`.

## C. Authentication
- Flutter `ApiInterceptor` sends **both** `Authorization: Bearer <jwt>` and `token: <jwt>`, plus `Accept`/`Content-Type: application/json`.
- Node `authMiddleware` accepts either header. JWT expiry 30d; invalid/missing → `401`. ✅
- Password: Laravel `$2y$` bcrypt, verified with `bcrypt.compare`. ✅
- **Manual step:** a real end-to-end login needs a production plaintext password (not to be exposed). Code path fully verified; wrong-password correctly returns `400`.

## D. Socket.IO / realtime
- Flutter uses a **raw WebSocket** (`ReverbService`, Pusher/Reverb style) to `ws://<host>:3009`.
- Node serves a **raw-WS Pusher-compatibility layer** at the root path alongside Socket.IO
  (verified: `pusher:connection_established` handshake, `pusher:subscribe`, keepalive).
- Event `dashboard.updated` (payload `{event, data:{user_id}}`) is emitted on order create /
  status change / delete and delivered to raw-WS clients. `GlobalAlertProvider` filters by
  `user_id` and calls `fetchDashboard` → refreshes dashboard, running token, and KDS. ✅
- Reconnect: Flutter auto-reconnects every 5s; server keepalive-pings every 25s. ✅

## E. KDS
- `KdsProvider.updateKds(orders)` aggregates **client-side** from the loaded orders
  (filters `pending`/`running`; sums `quantity` by item `name`; tracks unit + associated orders).
- Inputs come from the dashboard recent-orders set (Node maps `product_name`/`quantity`/`status`
  correctly). Dispatch/completion removes the order from pending/running → its quantity drops
  out of the aggregate (no duplicate quantities). ✅
- Realtime: a `dashboard.updated` event refreshes orders → KDS re-aggregates. ✅
- Note (pre-existing, not a schema issue): KDS aggregates from the dashboard recent-orders
  window (LIMIT 10), so very large active queues may exceed that window.

## F. POS / walk-in
- `POST /api/pos-order` → `orderRepository.createDirectOrder`, mapped to Laravel columns
  (`status`, `order_type`, `order_note`, `order_items.qty`, `order_date=NOW()`, non-null
  `payment_type`/`upi_amount`/`cash_amount`). Customer details, items, qty, note, payment
  (incl. part-payment amounts) all supported. Order appears in Takeaway + KDS. ✅
  (Variants/addons: not modeled in the Laravel `order_items` schema — see Issues.)

## G. QR / web ordering
- Public menu page `POST /public-api/menu/:slug/order` creates a **pending** order.
- Laravel `order_type` enum has no `qr`, so QR orders are stored as **`take_away`**.
  This does **not** break Flutter: the app treats any non-`dine_in` order as a token/takeaway
  order, and the Takeaway filter is `order_type != 'dine_in'`. ✅ (QR vs POS origin is not
  distinguishable in the DB — see Issues.)

## H. Dine-in / table ordering
- Mapped to the Laravel `orders` table (no `pending_tables`). Active table = order with
  `order_type='dine_in'` AND `status IN ('pending','running')`. **At most one active order per
  (user, table)** — verified from data and enforced by reusing the active order.
- Verified (automated, with cleanup): list active session, create, update same order (no
  duplicate), order-status update, finalize → `completed`, table leaves pending list. ✅

## I. Analytics
- PIN screen → `reports-analytics` with `user_pin`. Laravel PINs are **bcrypt-hashed**;
  verification switched to `bcrypt.compare`. Data query uses the `status` enum. ✅
- **Manual step:** verifying a successful unlock needs a real PIN (not exposed). Data query
  verified directly (e.g. user 16: ₹138,709 sales, 735 orders).

## J. Settings
- Read/update target `restaurant_settings` (Laravel). Reads return in-memory defaults when a
  row is missing — **no accidental INSERT**; existing Laravel settings untouched. `shop_open`
  (tinyint 0/1) is accepted by Flutter as int or string. ✅

## K. Device registration
- Login sends `device_id/device_type/fcm_token`. Node upserts into **`user_devices`** by
  (user_id, device_id) — INSERT or UPDATE, no duplicates. FCM tokens never logged.
  Verified (automated, with cleanup). ✅
- Minor: logout does not remove the device row (no-op) — optional to implement.

## L. Image URLs
- URL contract is correct: products `…/storage/products/<image>`, categories
  `…/uploads/categories/<image>` (matches Laravel). Laravel stores bare filenames
  (e.g. `1781242896_scaled_khaman-dhokla-recipe.jpg`).
- **Gap:** the image **files** are not in the local `backend/uploads/` (only the DB was
  recovered), so images 404 locally. Profile (`profile_image`) and QR (`qrcode_image`,
  e.g. `qr_9.svg`) have no dedicated Node static route. See Issues (asset availability, not a contract bug).

## M. Issues found
1. **Image assets missing locally** (not a code bug): copy the Laravel `storage` images into
   `backend/uploads/{products,categories}` (and add a static route for profile/QR images), or
   point `imageBaseUrl` to the live server, for images to render.
2. **QR order origin not distinguishable**: stored as `take_away` (Laravel enum has no `qr`).
   No Flutter breakage. Left as-is per instruction (do not change the Laravel enum).
3. **Variants/addons**: the Laravel `order_items` schema has no variant/addon columns; POS
   variant/addon selections (if any) are not persisted beyond name/qty/price. Needs product
   confirmation before any change.
4. **Logout device cleanup**: device row remains after logout (minor).
5. **Settings for a user with no `restaurant_settings` row**: `UPDATE` affects 0 rows (1 such
   user) — settings wouldn't persist until a row exists. Minor edge case.

## N. Files changed (this phase)
- `docs/FLUTTER_NODE_INTEGRATION_REPORT.md` (this report).
- **No code changes** — the Flutter↔Node contract is already compatible after the prior
  schema-mapping phases. Nothing else needed changing.

## O. Files NOT changed (intentionally)
- All Flutter code (models, datasources, providers, interceptor, ReverbService) — already
  compatible; no edits.
- Node repositories/services — already adapted in the previous phase.
- Laravel database — untouched (schema + data).

## P. Manual tests still required
1. **On-device run** against `http://192.168.1.3:3009/api/` (config already set for physical
   device): requires the Windows firewall rule for port 3009 and the cleartext/network-security
   rebuild already in the project. Then exercise each screen.
2. **Real login** with a production account (plaintext not to be exposed).
3. **Analytics unlock** with a real PIN.
4. **Image rendering** after the Laravel storage files are made available to Node.
5. **Realtime on device**: place an order from the web menu and confirm the dashboard/KDS
   update live on the phone.
