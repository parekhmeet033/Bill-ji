# LineLess MySQL Database Documentation & Schema Mapping

This document describes the database schema, table structures, column mappings, and constraints required to support the LineLess POS application while preserving compatibility with existing MySQL production data.

---

## Safety Rules for Production Database

1. **NO Destructive Operations:** Never run `DROP TABLE`, `TRUNCATE`, or `ALTER TABLE ... DROP COLUMN` against production MySQL databases.
2. **Preserve Primary Keys:** Retain existing auto-increment IDs (`BIGINT` / `INT`).
3. **Keep Existing Data Types:** Ensure data type compatibility (`DECIMAL(10,2)` for currency, `VARCHAR` for strings, `TIMESTAMP` for dates).
4. **Isolate Multi-Tenant Data:** Filter all queries by `user_id` (shop/restaurant owner ID) to prevent data leaking between restaurants.

---

## Database Table Mappings & Schema

### 1. `users` Table
Stores restaurant owner/admin credentials, profile details, and device registration.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` | Primary Key, Auto Increment | Restaurant / User ID |
| `name` | `VARCHAR(255)` | NOT NULL | Restaurant name / owner name |
| `email` | `VARCHAR(255)` | NOT NULL, UNIQUE | Login email |
| `password` | `VARCHAR(255)` | NOT NULL | Hashed password (Bcrypt) |
| `phone` | `VARCHAR(50)` | NULLABLE | Phone number |
| `role` | `VARCHAR(50)` | DEFAULT 'admin' | User role |
| `profile_image` | `VARCHAR(255)` | NULLABLE | Profile picture filename |
| `profile_banner` | `VARCHAR(255)` | NULLABLE | Banner image filename |
| `user_pin` | `VARCHAR(50)` | NULLABLE | PIN code for analytics report protection |
| `slug` | `VARCHAR(255)` | NULLABLE | URL slug for online menu |
| `fcm_token` | `VARCHAR(255)` | NULLABLE | Firebase FCM token for push notifications |
| `device_id` | `VARCHAR(255)` | NULLABLE | Connected POS device ID |
| `device_type` | `VARCHAR(50)` | NULLABLE | Android / iOS / Web |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Record creation timestamp |
| `updated_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | Record update timestamp |

---

### 2. `shop_settings` Table
Stores operational settings, operating hours, and mode configurations.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` | Primary Key, Auto Increment | Settings ID |
| `user_id` | `INT` / `BIGINT` | NOT NULL, Foreign Key -> `users(id)` | Restaurant ID |
| `shop_open` | `VARCHAR(10)` | DEFAULT '0' | `"0"` = Open, `"1"` = Closed |
| `morning_start` | `VARCHAR(10)` | DEFAULT '09:00' | Morning opening time |
| `morning_end` | `VARCHAR(10)` | DEFAULT '12:00' | Morning closing time |
| `afternoon_start` | `VARCHAR(10)` | DEFAULT '12:00' | Afternoon opening time |
| `afternoon_end` | `VARCHAR(10)` | DEFAULT '17:00' | Afternoon closing time |
| `evening_start` | `VARCHAR(10)` | DEFAULT '17:00' | Evening opening time |
| `evening_end` | `VARCHAR(10)` | DEFAULT '23:00' | Evening closing time |
| `category_display` | `VARCHAR(10)` | DEFAULT '1' | `"1"` = Show categories, `"0"` = Hide |
| `generated_code` | `VARCHAR(100)` | NULLABLE | POS Link / pairing code |
| `opration_mode_status` | `VARCHAR(50)` | DEFAULT 'both' | `'both'` \| `'takeaway'` \| `'dine_in'` |
| `number_of_tables` | `INT` | DEFAULT 10 | Number of tables in floor plan |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP ON UPDATE | |

---

### 3. `categories` Table
Stores menu categories (e.g. Starters, Main Course, Drinks).

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` | Primary Key, Auto Increment | Category ID |
| `user_id` | `INT` / `BIGINT` | NOT NULL, Foreign Key -> `users(id)` | Restaurant ID |
| `name` | `VARCHAR(255)` | NOT NULL | Category name |
| `image` | `VARCHAR(255)` | NULLABLE | Category image filename |
| `status` | `TINYINT` | DEFAULT 1 | `1` = Active, `0` = Inactive |
| `sort_order` | `INT` | DEFAULT 0 | Sorting display index |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP ON UPDATE | |

---

### 4. `products` Table (Menu Items)
Stores food menu products.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` | Primary Key, Auto Increment | Product ID |
| `user_id` | `INT` / `BIGINT` | NOT NULL, Foreign Key -> `users(id)` | Restaurant ID |
| `category_id` | `INT` / `BIGINT` | NOT NULL, Foreign Key -> `categories(id)` | Category ID |
| `name` | `VARCHAR(255)` | NOT NULL | Item name |
| `description` | `TEXT` | NULLABLE | Item description |
| `unit` | `VARCHAR(50)` | DEFAULT 'PLATE' | Item pricing unit (`PLATE`, `NOS`, `KG`, `QTY`) |
| `price` | `DECIMAL(10,2)` | NOT NULL | Full / regular price |
| `half_price` | `DECIMAL(10,2)` | NULLABLE | Half-portion price (for `PLATE` unit) |
| `image` | `VARCHAR(255)` | NULLABLE | Image filename |
| `status` | `TINYINT` | DEFAULT 1 | `1` = Available, `0` = Out of Stock |
| `sort_order` | `INT` | DEFAULT 0 | Display order within category |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP ON UPDATE | |

---

### 5. `orders` Table
Stores overall order information.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` | Primary Key, Auto Increment | Order ID |
| `user_id` | `INT` / `BIGINT` | NOT NULL, Foreign Key -> `users(id)` | Restaurant ID |
| `token_no` | `VARCHAR(50)` | NOT NULL | Token / Queue number |
| `table_no` | `INT` | NULLABLE | Table number if dine-in |
| `customer_name` | `VARCHAR(255)` | DEFAULT 'Walk-in Customer' | Customer name |
| `customer_mobile` | `VARCHAR(50)` | DEFAULT 'N/A' | Customer phone |
| `total_amount` | `DECIMAL(10,2)` | NOT NULL | Order total |
| `order_status` | `VARCHAR(50)` | DEFAULT 'pending' | `'pending'`, `'running'`, `'completed'`, `'dispatched'`, `'cancelled'` |
| `order_type` | `VARCHAR(50)` | DEFAULT 'dine_in' | `'dine_in'`, `'takeaway'`, `'qr'` |
| `payment_type` | `VARCHAR(50)` | NULLABLE | `'cash'`, `'upi'`, `'part_payment'` |
| `upi_amount` | `DECIMAL(10,2)` | NULLABLE | UPI payment portion |
| `cash_amount` | `DECIMAL(10,2)` | NULLABLE | Cash payment portion |
| `special_note` | `TEXT` | NULLABLE | Customer / Order note |
| `order_date` | `DATETIME` / `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | Order creation date/time |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP ON UPDATE | |

---

### 6. `order_items` Table
Stores individual line items of an order.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` | Primary Key, Auto Increment | Order Item ID |
| `order_id` | `INT` / `BIGINT` | NOT NULL, Foreign Key -> `orders(id)` | Associated Order ID |
| `product_id` | `INT` / `BIGINT` | NULLABLE | Reference product ID |
| `product_name` | `VARCHAR(255)` | NOT NULL | Item name at time of order |
| `quantity` | `DECIMAL(10,2)` | NOT NULL | Quantity ordered |
| `unit` | `VARCHAR(50)` | DEFAULT 'PLATE' | Unit (`PLATE`, `NOS`, `KG`) |
| `price` | `DECIMAL(10,2)` | NOT NULL | Unit price |
| `total` | `DECIMAL(10,2)` | NOT NULL | Total price for item |
| `created_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | `TIMESTAMP` | DEFAULT CURRENT_TIMESTAMP ON UPDATE | |

---

### 7. `pending_tables` & `pending_table_items` Tables
Stores active, unbilled waiter/table carts before final bill generation.

#### `pending_tables`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` Primary Key | Active table session ID |
| `user_id` | `INT` / `BIGINT` Foreign Key | Restaurant ID |
| `table_no` | `INT` NOT NULL | Table Number |
| `customer_name` | `VARCHAR(255)` | Customer name |
| `customer_mobile` | `VARCHAR(50)` | Customer mobile |
| `order_note` | `TEXT` | Notes |
| `total_amount` | `DECIMAL(10,2)` | Current cart total |
| `created_at`, `updated_at` | `TIMESTAMP` | Timestamps |

#### `pending_table_items`
| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `INT` / `BIGINT` Primary Key | Item ID |
| `pending_table_id` | `INT` / `BIGINT` Foreign Key | Session ID |
| `product_id` | `INT` / `BIGINT` Foreign Key | Product ID |
| `product_name` | `VARCHAR(255)` | Product name |
| `unit` | `VARCHAR(50)` | Unit |
| `qty` | `DECIMAL(10,2)` | Quantity |
| `price` | `DECIMAL(10,2)` | Price |
| `total` | `DECIMAL(10,2)` | Total |
| `created_at`, `updated_at` | `TIMESTAMP` | Timestamps |

---

## Relational Diagram Overview

```
 [users] (1) <--- (N) [shop_settings]
    |
    +--- (1) <--- (N) [categories] (1) <--- (N) [products]
    |                                                |
    +--- (1) <--- (N) [orders] (1) <--- (N) [order_items]
    |
    +--- (1) <--- (N) [pending_tables] (1) <--- (N) [pending_table_items]
```

---

## Database Connection Configuration

The Node.js backend connects using MySQL parameters provided via `.env`:
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=lineless_db
```
