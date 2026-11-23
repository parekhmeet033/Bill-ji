# LineLess API Documentation (Node.js Express Backend)

Base URL: `http://localhost:3009/api/` (or production URL `https://your-domain.com/api/`)

---

## Headers Required for Protected Endpoints
```http
Authorization: Bearer <token>
token: <token>
Accept: application/json
Content-Type: application/json
```

---

## Endpoints

### 1. Authentication

#### `POST /api/login`
- **Authentication:** None
- **Request Body:**
  ```json
  {
    "email": "admin@example.com",
    "password": "password123",
    "device_id": "device_123",
    "device_type": "android",
    "fcm_token": "fcm_token_xyz"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "status": true,
    "success": true,
    "message": "Login successful",
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "data": {
      "id": 1,
      "name": "Restaurant Owner",
      "email": "admin@example.com",
      "phone": "9876543210",
      "role": "admin",
      "profile_image": null
    }
  }
  ```

#### `POST /api/logout`
- **Authentication:** Required
- **Request Body:** `{ "device_id": "device_123" }`
- **Response (200 OK):** `{ "status": true, "success": true, "message": "Successfully logged out" }`

#### `POST /api/forgot-pin`
- **Authentication:** Required
- **Request Body:** `{ "old_pin": "1234", "new_pin": "5678" }`
- **Response (200 OK):** `{ "status": true, "success": true, "message": "PIN updated successfully" }`

---

### 2. Dashboard & Settings

#### `POST /api/dashboard`
- **Authentication:** Required
- **Response (200 OK):**
  ```json
  {
    "status": true,
    "success": true,
    "message": "Dashboard data fetched",
    "data": {
      "user_id": 1,
      "user_name": "LineLess Test Restaurant",
      "profile_banner": null,
      "running_token": "10",
      "today_total_orders": 25,
      "today_pending_orders": 3,
      "today_completed_orders": 18,
      "today_dispatched_orders": 4,
      "generated_code": "POS101",
      "slug": "lineless-test",
      "opration_mode_status": "both",
      "number_of_tables": 10,
      "recent_orders": []
    }
  }
  ```

#### `POST /api/settings`
- **Authentication:** Required
- **Request Body (Get):** `{ "type": "get" }`
- **Request Body (Update):**
  ```json
  {
    "type": "",
    "shop_open": "0",
    "morning_start": "09:00",
    "morning_end": "12:00",
    "afternoon_start": "12:00",
    "afternoon_end": "17:00",
    "evening_start": "17:00",
    "evening_end": "23:00",
    "category_display": "1",
    "generated_code": "POS101",
    "opration_mode_status": "both",
    "number_of_tables": 10
  }
  ```
- **Response (200 OK):** `{ "status": true, "success": true, "message": "Settings updated", "data": { ... } }`

---

### 3. Menu & Category Management

#### `POST /api/category-list`
- **Authentication:** Required
- **Response (200 OK):** `{ "status": true, "message": "Categories fetched", "data": [...] }`

#### `POST /api/category-add` (multipart/form-data)
- **Form Fields:** `name` (string), `image` (file, optional)
- **Response (200 OK):** `{ "status": true, "message": "Category added successfully" }`

#### `POST /api/category-update` (multipart/form-data)
- **Form Fields:** `id` (int), `name` (string), `image` (file, optional)
- **Response (200 OK):** `{ "status": true, "message": "Category updated successfully" }`

#### `POST /api/category-destroy`
- **Request Body:** `{ "id": 1 }`
- **Response (200 OK):** `{ "status": true, "message": "Category deleted successfully" }`

#### `POST /api/category-reorder`
- **Request Body:** `{ "categories": [{ "id": 2 }, { "id": 1 }] }`
- **Response (200 OK):** `{ "status": true, "message": "Categories reordered successfully" }`

#### `POST /api/menu-list`
- **Authentication:** Required
- **Response (200 OK):** `{ "status": true, "message": "Menu items fetched", "product": [...] }`

#### `POST /api/menu-add` (multipart/form-data)
- **Form Fields:** `category_id`, `name`, `unit`, `price`, `description`, `half_price`, `image`
- **Response (200 OK):** `{ "status": true, "message": "Product added successfully", "data": { ... } }`

#### `POST /api/menu-update` (multipart/form-data)
- **Form Fields:** `id`, `category_id`, `name`, `unit`, `price`, `description`, `half_price`, `image`
- **Response (200 OK):** `{ "status": true, "message": "Product updated successfully", "data": { ... } }`

#### `POST /api/menu-destroy`
- **Request Body:** `{ "product_id": "10" }`
- **Response (200 OK):** `{ "status": true, "message": "Product deleted successfully" }`

#### `POST /api/menu-status`
- **Request Body:** `{ "product_id": "10", "status": 0 }`
- **Response (200 OK):** `{ "status": true, "message": "Status updated successfully" }`

#### `POST /api/menu-reorder`
- **Request Body:** `{ "category_id": 1, "product_ids": [{ "id": 10 }] }`
- **Response (200 OK):** `{ "status": true, "message": "Menu reordered successfully" }`

#### `POST /api/table-product-list`
- **Authentication:** Required
- **Response (200 OK):** `{ "status": true, "message": "Table product list fetched", "data": [...] }`

---

### 4. Orders & Table Ordering

#### `POST /api/orders-list`
- **Request Body:** `{ "status": "All", "order_type": "All", "search": "", "start_date": "", "end_date": "", "page": 1 }`
- **Response (200 OK):** `{ "status": true, "message": "Orders fetched", "data": [...], "pagination": { ... } }`

#### `POST /api/orders-status`
- **Request Body:** `{ "order_id": "101", "status": "running", "payment_type": "cash", "upi_amount": 0, "cash_amount": 250 }`
- **Response (200 OK):** `{ "status": true, "message": "Order status updated successfully" }`

#### `POST /api/orders-deleted`
- **Request Body:** `{ "start_date": "2026-10-01", "end_date": "2026-10-04" }`
- **Response (200 OK):** `{ "status": true, "message": "Orders deleted successfully" }`

#### `POST /api/save-table-order`
- **Request Body:** `{ "table_no": 5, "customer_name": "John", "customer_mobile": "9876543210", "order_note": "", "total_amount": 250, "order_status": "pending", "items": [...], "remove_items": [] }`
- **Response (200 OK):** `{ "status": true, "message": "Table order saved" }`

#### `POST /api/pending-tables`
- **Authentication:** Required
- **Response (200 OK):** `{ "status": true, "message": "Pending tables fetched", "data": [...] }`

---

### 5. Reports & Analytics

#### `POST /api/reports-analytics`
- **Request Body:** `{ "user_pin": "1234" }` (optional if PIN set)
- **Response (200 OK):** `{ "status": true, "message": "Analytics fetched", "data": { ... } }`
