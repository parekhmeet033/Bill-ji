# LineLess — Laravel Schema Compatibility Mapping

The recovered **`lineless`** (Laravel) database is the **source of truth**. The Node.js
backend has been adapted to read/write the existing Laravel tables **without changing
the Laravel schema**.

> **No DB schema changes were made to any original Laravel table.** No columns added,
> renamed, dropped, or migrated; no Laravel data modified. The server runs with
> `DB_INIT_SCHEMA=false`, so startup creates/alters nothing.
> (Separately, 2 empty Node-created tables — `pending_tables`, `pending_table_items` —
> were removed with authorization; `shop_settings` (1 Node-generated row) is pending a
> drop decision. None are Laravel tables.)

Flutter API response field names are **unchanged**; only the SQL source columns differ.

---

## users  (13 rows)
Actual columns: `id, name, email, phone, user_pin, slug, password, role, status, profile_image, qrcode_image, remember_token, plan_start_date, plan_end_date, created_at, updated_at`

| Node response field | Laravel column | Notes / transformation |
|---|---|---|
| id, name, email, phone, role, profile_image | same | direct |
| password | `password` | **bcrypt `$2y$`** — verified with `bcrypt.compare` (bcryptjs handles `$2y$`) |
| user_pin | `user_pin` | **bcrypt-hashed** — verified with `bcrypt.compare` (was plaintext `!==`) |

- **No** `device_id/device_type/fcm_token` columns (devices live in `user_devices`). The
  login device update is now wrapped in try/catch so it is non-fatal (repository: `userRepository.updateDeviceAndFcmToken`).
- **No** `profile_banner` column → dashboard returns `null` (JS property read, no SQL error).
- Affected: `authController.login/forgotPin`, `reportService` (PIN), `userRepository`.

## categories  (109 rows)
Actual columns: `id, user_id, name, image, status, sort_order, created_at, updated_at` — matches Node.
- `products_count` subquery now filters `AND p.deleted_at IS NULL`.
- Affected: `menuController.getCategoryList`, `menuRepository.getCategories`.

## products  (941 rows; 112 soft-deleted)
Actual columns: `id, user_id, category_id, name, description, unit, price, half_price, image, stock, type, status, sort_order, created_at, updated_at, deleted_at`
- Laravel uses **soft deletes** → all product reads now add `AND deleted_at IS NULL`
  (`getProducts`, `getTableProducts`, category product counts).
- Columns otherwise match Node assumptions.
- `menuRepository.deleteProduct` now **soft-deletes** (`deleted_at = NOW()`) — see "Product soft-delete mapping".
- Affected: `menuController.getMenuList/getTableProductList`, `menuRepository`.

## orders  (2542 rows)
Actual columns: `id, user_id, customer_name, customer_mobile, order_note, token_no, table_no, total_amount, payment_type ENUM('upi','cash','part_payment'), upi_amount, cash_amount, estimate_time, status ENUM('pending','running','completed','cancelled','dispatched'), order_status (legacy varchar, mostly NULL), order_type ENUM('take_away','dine_in'), order_date, cashfree_order_id, created_at, updated_at`

| Node used before | Laravel actual | Fix |
|---|---|---|
| `order_status` (for status) | **`status`** (enum) | all reads/writes now use `status` (`order_status` is legacy/unused) |
| `started_at` | **does not exist** | running-token now derived from `status='running'` (no persistence column) |
| `special_note` (response) | **`order_note`** | mapped: response key stays `special_note`, sourced from `order_note` |
| `order_type='takeaway'/'qr'` | enum **`take_away'/'dine_in'`** | reads filter `order_type != 'dine_in'` for takeaway; writes map non-dine-in → `take_away` |

- Affected endpoints: `POST /api/dashboard`, `POST /api/orders-list`, `POST /api/orders-status`, `POST /api/reports-analytics`, admin dashboard stats.
- Fixed the two reported errors: `Unknown column 'started_at'` (dashboard) and (via order_items) `Unknown column 'quantity'` (orders-list).

## order_items  (6094 rows)
Actual columns: `id, order_id, product_id, product_name, price, qty (varchar), unit, total, created_at, updated_at`

| Node used before | Laravel actual | Fix |
|---|---|---|
| `quantity` | **`qty`** (varchar) | SELECT/INSERT use `qty`; response key stays `quantity` (stringified) |

## restaurant_settings  (12 rows)  ← Node expected `shop_settings`
Actual columns: `id, user_id (UNIQUE), shop_open TINYINT(1), category_display TINYINT, generated_code, morning_start..evening_end TIME, opration_mode_status ENUM('both','takeaway','dine_in'), number_of_tables, created_at, updated_at`
- `settingsRepository` and `userRepository.getShopBySlug` now query **`restaurant_settings`** (not `shop_settings`).
- `getByUserId` returns in-memory defaults when a row is missing (no auto-INSERT) so reads never write to the Laravel table.
- `shop_open` is `0/1` (tinyint); times are `HH:MM:SS`.
- Affected: `POST /api/settings`, public `/public-api/shop/:slug` (menu page).

## user_devices  (33 rows)
Actual columns: `id, user_id, device_id, device_type, fcm_token, sanctum_token_id, created_at, updated_at`
- Device registration writes here (not `users`) — upsert by (user_id, device_id). See "Device registration mapping".

## migrations
Laravel framework table — read-only reference; confirmed the 3 Node tables were **not** Laravel-managed.

---

## Dine-in session mapping (IMPLEMENTED — no new tables)
Laravel has no `pending_tables`/`pending_table_items`. An active (unbilled) table IS an
order: `order_type='dine_in' AND status IN ('pending','running')`. Verified from data:
**at most one active dine-in order per (user_id, table_no)**. `tableRepository`:
- `getPendingTables(userId)` → selects active dine-in orders + their `order_items`,
  shaped as the Flutter `PendingTableModel` (table_no, customer_name, customer_mobile,
  order_note, total_amount, items[{product_id, product_name, unit, qty, price, total, created_at}]).
- `saveTableOrder(userId, data)`:
  - finds the active dine-in order for (user, table_no);
  - **pending/running**: updates that order (and replaces its items with the current cart),
    or inserts a new `dine_in` order (token_no = table_no) if none exists;
  - **completed/dispatched**: flips the same order's `status` and records payment.
  One active order per table is enforced by always reusing the found active order.

## Product soft-delete mapping (IMPLEMENTED)
`menuRepository.deleteProduct` now does `UPDATE products SET deleted_at = NOW()` (never a
hard DELETE). All product reads exclude `deleted_at IS NOT NULL`
(`getProducts`, `getProductById`, `getTableProducts`, category counts).

## Device registration mapping (IMPLEMENTED — `user_devices`)
`user_devices` columns: `id, user_id, device_id, device_type, fcm_token, sanctum_token_id, created_at, updated_at`.
`userRepository.updateDeviceAndFcmToken(userId, deviceId, deviceType, fcmToken)` upserts by
(user_id, device_id): UPDATE if the pair exists else INSERT. No-ops when deviceId is absent
(e.g. logout). FCM tokens are never logged. Devices are no longer written to `users`.

## Why no new DB tables were required
Every feature maps onto existing Laravel tables: dine-in sessions → `orders`(+`order_items`),
settings → `restaurant_settings`, devices → `user_devices`, soft-delete → `products.deleted_at`.
The Node-only `shop_settings`/`pending_tables`/`pending_table_items` were therefore removed.

## Remaining write-path caveats
- Order creation (`createDirectOrder`, POS/QR/web-POS): QR orders are stored as `take_away`
  (Laravel `order_type` enum has no `qr` value), so QR vs merchant-POS origin is not distinguished.
- Settings/PIN updates write to Laravel tables as normal app actions (PIN stored bcrypt-hashed).

## Verified (read-only) against real data (merchant user_id=16)
- login lookup + bcrypt `$2y$` verification (synthetic + all 13 hashes parse) ✅
- dashboard (today totals, running token, 10 recent orders w/ items) ✅
- orders-list (All + status/type filters; 735 total) ✅
- category-list (11) ✅, menu-list (130, soft-deletes excluded) ✅
- reports-analytics data query (₹138,709 sales, 735 orders) ✅ — PIN gate is bcrypt-verified
- settings (restaurant_settings) ✅, pending-tables (empty, safe) ✅
- realtime: Socket.IO + raw-WS emit path is schema-independent ✅
