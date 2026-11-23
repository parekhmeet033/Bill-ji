# LineLess Flutter Project - Backend Analysis & API Contract Specification

This document provides a complete reverse-engineered analysis of the existing LineLess Flutter application, its API contracts, WebSocket implementation, models, data structures, and business rules.

---

## 1. Executive Summary & Architecture Overview

**LineLess** is a POS and Order Management Application for restaurants ("No Queue, Zero Wait").
- **App Type:** Flutter mobile/tablet/desktop POS application.
- **Backend Paradigm:** REST API (JSON / FormData) + Real-time WebSockets.
- **Authentication:** Bearer Token authentication sent via HTTP Headers (`Authorization: Bearer <token>` and `token: <token>`).
- **Realtime System:** Previously Laravel Reverb / Pusher WebSocket protocol listening on channel `dashboard` for event `dashboard.updated`.

---

## 2. Authentication & Request Headers

### Headers Sent by App Interceptor (`ApiInterceptor`)
- `Authorization`: `Bearer <token>`
- `token`: `<token>`
- `Accept`: `application/json`
- `Content-Type`: `application/json` (or `multipart/form-data` for file uploads)

---

## 3. Complete API Endpoint Specification

### 3.1 Authentication & User Management

#### 1. `POST /api/login`
- **Description:** Authenticates user and returns access token and profile info.
- **Request Body:**
  ```json
  {
    "email": "string",
    "password": "string",
    "device_id": "string (optional)",
    "device_type": "string (optional)",
    "fcm_token": "string (optional)"
  }
  ```
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Login successful",
    "token": "1|abcdef123456...",
    "data": {
      "id": 1,
      "name": "Restaurant Name",
      "email": "admin@example.com",
      "phone": "9876543210",
      "role": "admin",
      "profile_image": "profile.jpg"
    }
  }
  ```

#### 2. `POST /api/logout`
- **Description:** Invalidates user session and removes device token.
- **Request Body:**
  ```json
  {
    "device_id": "string (optional)"
  }
  ```
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Successfully logged out"
  }
  ```

#### 3. `POST /api/forgot-pin`
- **Description:** Updates/resets report access PIN for analytics.
- **Request Body:**
  ```json
  {
    "old_pin": "string",
    "new_pin": "string"
  }
  ```
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "PIN updated successfully"
  }
  ```

---

### 3.2 Dashboard & Settings

#### 4. `POST /api/dashboard`
- **Description:** Retrieves real-time dashboard stats and recent orders.
- **Request Body:** None / `{}`
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Dashboard data fetched",
    "data": {
      "user_id": 1,
      "user_name": "GoalScripture Test Shop",
      "profile_banner": "banner.jpg",
      "running_token": "15",
      "today_total_orders": 45,
      "today_pending_orders": 5,
      "today_completed_orders": 30,
      "today_dispatched_orders": 10,
      "generated_code": "POS123",
      "slug": "goalscripture-test-shop",
      "opration_mode_status": "both",
      "number_of_tables": 10,
      "recent_orders": [
        {
          "order_id": 101,
          "token_no": "15",
          "customer_name": "John Doe",
          "customer_mobile": "9876543210",
          "total_amount": 250.0,
          "order_date": "2026-10-04 12:30:00",
          "status": "pending",
          "special_note": "Extra spicy",
          "order_type": "dine_in",
          "payment_type": "cash",
          "items": [
            {
              "product_id": 5,
              "product_name": "Paneer Butter Masala",
              "quantity": "2",
              "price": 100.0,
              "total": 200.0,
              "unit": "plate"
            }
          ]
        }
      ]
    }
  }
  ```

#### 5. `POST /api/settings`
- **Description:** Retrieves or updates shop settings.
- **Get Settings Request Body:**
  ```json
  {
    "type": "get"
  }
  ```
- **Update Settings Request Body:**
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
    "generated_code": "ABC123XYZ",
    "opration_mode_status": "both",
    "number_of_tables": 10
  }
  ```
  *(Note: shop_open: "0" = Open, "1" = Closed in Flutter ShopSettingsModel)*
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Settings updated",
    "data": {
      "id": 1,
      "user_id": 1,
      "shop_open": "0",
      "morning_start": "09:00",
      "morning_end": "12:00",
      "afternoon_start": "12:00",
      "afternoon_end": "17:00",
      "evening_start": "17:00",
      "evening_end": "23:00",
      "category_display": "1",
      "generated_code": "ABC123XYZ",
      "opration_mode_status": "both",
      "number_of_tables": 10
    }
  }
  ```

---

### 3.3 Menu & Category Management

#### 6. `POST /api/category-list`
- **Description:** Returns categories with product counts and product lists.
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Categories fetched",
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "name": "Starters",
        "image": "category_starters.jpg",
        "status": 1,
        "sort_order": 1,
        "products_count": 12,
        "products": []
      }
    ]
  }
  ```

#### 7. `POST /api/category-add` (multipart/form-data)
- **Form Fields:** `name` (string, required), `image` (file, optional)
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Category added successfully"
  }
  ```

#### 8. `POST /api/category-update` (multipart/form-data)
- **Form Fields:** `id` (int, required), `name` (string, required), `image` (file, optional)
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Category updated successfully"
  }
  ```

#### 9. `POST /api/category-destroy`
- **Request Body:** `{ "id": 1 }`
- **Response Structure:** `{ "status": true, "message": "Category deleted" }`

#### 10. `POST /api/category-reorder`
- **Request Body:**
  ```json
  {
    "categories": [
      { "id": 2 },
      { "id": 1 }
    ]
  }
  ```
- **Response Structure:** `{ "status": true, "message": "Categories reordered successfully" }`

#### 11. `POST /api/menu-list`
- **Description:** Returns all menu products for the restaurant.
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Menu items fetched",
    "product": [
      {
        "id": 10,
        "category_id": 1,
        "category_name": "Starters",
        "category_image": "category_starters.jpg",
        "name": "Paneer Tikka",
        "description": "Grilled marinated cottage cheese",
        "unit": "PLATE",
        "price": "180.00",
        "half_price": "100.00",
        "image": "paneer_tikka.jpg",
        "status": 1
      }
    ]
  }
  ```

#### 12. `POST /api/menu-add` (multipart/form-data)
- **Form Fields:**
  - `category_id` (int, required)
  - `name` (string, required)
  - `unit` (string: "KG", "QTY", "NOS", "PLATE", required)
  - `price` (string/number, required)
  - `description` (string, optional)
  - `half_price` (string/number, optional)
  - `image` (file, required)
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Product added successfully",
    "data": {
      "id": "11",
      "category_id": 1,
      "category_name": "Starters",
      "name": "Spring Roll",
      "description": "Crispy vegetable rolls",
      "unit": "NOS",
      "price": "120.00",
      "half_price": null,
      "image": "spring_roll.jpg",
      "status": 1
    }
  }
  ```

#### 13. `POST /api/menu-update` (multipart/form-data)
- **Form Fields:** `id` (required), `category_id`, `name`, `unit`, `price`, `description`, `half_price`, `image` (optional file)
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Product updated successfully",
    "data": { ... }
  }
  ```

#### 14. `POST /api/menu-destroy`
- **Request Body:** `{ "product_id": "11" }`
- **Response Structure:** `{ "status": true, "message": "Product deleted successfully" }`

#### 15. `POST /api/menu-status`
- **Request Body:** `{ "product_id": "11", "status": 0 }` (0 = Unavailable, 1 = Available)
- **Response Structure:** `{ "status": true, "success": true, "message": "Status updated" }`

#### 16. `POST /api/menu-reorder`
- **Request Body:**
  ```json
  {
    "category_id": 1,
    "product_ids": [
      { "id": 12 },
      { "id": 10 }
    ]
  }
  ```
- **Response Structure:** `{ "status": true, "message": "Menu reordered" }`

#### 17. `POST /api/table-product-list`
- **Description:** Returns product categories and products formatted for table ordering UI.
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Table product list fetched",
    "data": [
      {
        "id": 1,
        "name": "Starters",
        "image": "category.jpg",
        "products": [
          {
            "id": 10,
            "category_id": 1,
            "name": "Paneer Tikka",
            "description": "Grilled marinated paneer",
            "unit": "PLATE",
            "price": "180.00",
            "half_price": "100.00",
            "image": "paneer_tikka.jpg"
          }
        ]
      }
    ]
  }
  ```

---

### 3.4 Orders, Tables, Reports & POS

#### 18. `POST /api/orders-list`
- **Request Body:**
  ```json
  {
    "status": "All",
    "order_type": "All",
    "search": "",
    "start_date": "2026-10-01",
    "end_date": "2026-10-04",
    "page": 1
  }
  ```
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Orders fetched",
    "data": [
      {
        "order_id": "101",
        "token_no": "15",
        "customer_name": "John Doe",
        "customer_mobile": "9876543210",
        "total_amount": 250.0,
        "order_date": "2026-10-04 12:30:00",
        "status": "pending",
        "special_note": "",
        "order_type": "dine_in",
        "payment_type": "cash",
        "items": [
          {
            "product_id": 5,
            "product_name": "Paneer Tikka",
            "quantity": "1",
            "price": 180.0,
            "total": 180.0,
            "unit": "PLATE"
          }
        ]
      }
    ],
    "pagination": {
      "current_page": 1,
      "last_page": 5,
      "per_page": 10,
      "total": 45,
      "next_page_url": "...",
      "prev_page_url": null
    }
  }
  ```

#### 19. `POST /api/orders-status`
- **Request Body:**
  ```json
  {
    "order_id": "101",
    "status": "running",
    "payment_type": "cash",
    "upi_amount": 0.0,
    "cash_amount": 250.0
  }
  ```
- **Response Structure:**
  ```json
  {
    "success": true,
    "status": true,
    "message": "Order status updated successfully"
  }
  ```

#### 20. `GET /api/orders`
- **Description:** Directly fetches order list entity representation.
- **Response Structure:**
  ```json
  {
    "status": true,
    "data": [
      {
        "id": "101",
        "token_number": "15",
        "customer_name": "John Doe",
        "customer_mobile": "9876543210",
        "total_amount": 250.0,
        "created_at": "2026-10-04T12:30:00.000Z",
        "status": "pending",
        "special_note": "",
        "order_type": "dine_in",
        "payment_type": "cash",
        "items": [
          {
            "product_id": 5,
            "name": "Paneer Tikka",
            "quantity": "1",
            "price": 180.0,
            "unit": "PLATE"
          }
        ]
      }
    ]
  }
  ```

#### 21. `POST /api/orders-deleted`
- **Request Body:**
  ```json
  {
    "start_date": "2026-10-01",
    "end_date": "2026-10-04"
  }
  ```
- **Response Structure:** `{ "status": true, "message": "Orders deleted successfully" }`

#### 22. `POST /api/save-table-order`
- **Description:** Saves waiter/table order (pending KOT or final order).
- **Request Body:**
  ```json
  {
    "table_no": 5,
    "customer_name": "Jane",
    "customer_mobile": "9876543211",
    "order_note": "Corner table",
    "total_amount": 350.0,
    "order_status": "pending",
    "items": [
      {
        "product_id": 10,
        "product_name": "Paneer Tikka",
        "price": 180.0,
        "qty": 1.0,
        "unit": "PLATE",
        "total": 180.0
      }
    ],
    "remove_items": [3],
    "payment_type": "upi",
    "upi_amount": 350.0,
    "cash_amount": 0.0
  }
  ```
- **Response Structure:** `{ "status": true, "message": "Table order saved" }`

#### 23. `POST /api/pending-tables`
- **Description:** Gets all tables currently having unbilled or pending active orders.
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Pending tables fetched",
    "data": [
      {
        "table_no": 5,
        "customer_name": "Jane",
        "customer_mobile": "9876543211",
        "order_note": "Corner table",
        "total_amount": 350.0,
        "items": [
          {
            "product_id": 10,
            "product_name": "Paneer Tikka",
            "unit": "PLATE",
            "qty": 1.0,
            "price": 180.0,
            "total": 180.0,
            "created_at": "2026-10-04 12:40:00"
          }
        ]
      }
    ]
  }
  ```

#### 24. `POST /api/reports-analytics`
- **Request Body:**
  ```json
  {
    "user_pin": "1234"
  }
  ```
- **Response Structure:**
  ```json
  {
    "status": true,
    "message": "Analytics fetched",
    "data": {
      "today_revenue": 12500.0,
      "total_sales": 350000.0,
      "total_orders": 1250,
      "orders_cancelled": 12,
      "weekly_sales": 87500.0,
      "today_upi_payment": 7500.0,
      "today_cash_payment": 5000.0,
      "total_upi_sales": 200000.0,
      "total_cash_sales": 150000.0
    }
  }
  ```

---

## 4. Real-time Infrastructure (Reverb → Socket.IO Mapping)

### Current Reverb Setup
- **Channel:** `dashboard`
- **Event:** `dashboard.updated`
- **Payload:**
  ```json
  {
    "event": "dashboard.updated",
    "data": {
      "user_id": "1"
    }
  }
  ```
- **Flutter Action:** When `dashboard.updated` is received, `GlobalAlertProvider` verifies `user_id` matches the logged-in restaurant `user_id`, triggers `fetchDashboard(isRealtime: true)`, plays audio alert, enqueues new orders for thermal printing.

### Socket.IO Replacement Design
To allow effortless migration or Socket.IO integration:
- **Namespaces / Rooms:** Each shop is isolated into room `shop_<user_id>` (e.g., `shop_1`).
- **Events Emitted by Node.js Backend:**
  - `dashboard.updated` with `{ "user_id": "1" }`
  - Additional rich events for future compatibility: `order.new`, `order.updated`, `table.updated`, `kds.updated`.

---

## 5. Storage & Static Assets Structure

- Products Base URL: `/storage/products/<filename>`
- Categories Base URL: `/uploads/categories/<filename>`
- Express static file serving configured to map `/storage/products` and `/uploads/categories` to local `/backend/uploads` directories.

