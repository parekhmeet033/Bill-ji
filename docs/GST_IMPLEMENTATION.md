# LineLess GST Billing Feature Implementation Documentation

This document details the complete end-to-end GST Billing feature implementation across the LineLess Flutter POS application, Node.js backend, MySQL database, and Thermal Printing service.

---

## 1. Feature Architecture Overview

The GST Billing feature is built as a **server-authoritative, snapshot-based** tax engine:
- **Product GST Configuration:** Each product can individually be marked `gst_applicable = true` with a designated `gst_rate` (0%, 5%, 12%, 18%, 28%).
- **Restaurant GST Setting:** The restaurant owner can enable or disable GST calculation on bills globally (`gst_enabled = true/false`).
- **GST Snapshot:** When an order is placed (POS, Table Order, Customer QR, Takeaway, Dine-in), an immutable GST snapshot is saved on each order item (`taxable_amount`, `gst_applicable`, `gst_rate`, `gst_amount`, `total`).
- **Historical Preservation:** Updating a product's GST rate or turning GST OFF in settings later will **never** alter historical orders or completed bills.

---

## 2. Product GST Configuration

### Flutter UI (`AddMenuItemDialog` & `AddMenuItemProvider`)
- Added **GST Applicable** toggle switch.
- When `GST Applicable` is ON, a **GST Rate** dropdown displays selectable rates: `0%`, `5%`, `12%`, `18%`, `28%` (default: `5%`).
- When `GST Applicable` is OFF, the GST Rate dropdown is hidden and set to `0%`.

### Backend API
- `POST /api/menu-add` and `POST /api/menu-update` accept:
  - `gst_applicable`: `"1"` or `"0"`
  - `gst_rate`: `"0.00"`, `"5.00"`, `"12.00"`, `"18.00"`, `"28.00"`
- Exposed in product models (`MenuItemModel`, `MenuItemApiModel`, `TableProductModel`).

---

## 3. Restaurant GST Settings & Business Details

### Flutter UI (`SettingsScreen` & `SettingsProvider`)
- Added **GST Billing** section:
  - `Enable GST on Bills` switch (`gst_enabled`).
- Added **GST Business Details** section (Optional):
  - `GSTIN`
  - `Legal Business Name`
  - `Business Address`
  - `State`
  - `State Code`

### Backend API & Database
- `POST /api/settings` accepts:
  - `gst_enabled`: `"1"` / `"0"`
  - `gstin`, `legal_business_name`, `business_address`, `state`, `state_code`.

---

## 4. GST Calculation Rules & Order Snapshot

### Server-Authoritative Logic (`orderRepository.js` & `tableRepository.js`)

1. **Check Restaurant Setting:**
   If `gst_enabled == 0` for the restaurant, no GST is added to the order. All items have `gst_amount = 0`, `taxable_amount = quantity * unit_price`, `total = taxable_amount`.

2. **When `gst_enabled == 1`:**
   For each item in the order:
   - `taxable_amount = quantity * unit_price`
   - If item `gst_applicable == 1`:
     - `item_gst_amount = taxable_amount * (gst_rate / 100)`
     - `item_total = taxable_amount + item_gst_amount`
   - If item `gst_applicable == 0`:
     - `item_gst_rate = 0.00`
     - `item_gst_amount = 0.00`
     - `item_total = taxable_amount`

3. **Order Totals & Intra-State Tax Split (CGST / SGST / IGST):**
   - `subtotal_amount = sum(item.taxable_amount)`
   - `gst_amount = sum(item.item_gst_amount)`
   - `cgst_amount = gst_amount / 2`
   - `sgst_amount = gst_amount / 2`
   - `total_amount = subtotal_amount + gst_amount`

---

## 5. Billing & Thermal Printing (`PrinterService` & `OrderDetailsScreen`)

- **Order Details & Order Card UI:**
  When `gst_amount > 0`, the bill summary displays:
  ```text
  Subtotal:          ₹450.00
  CGST @ 2.5%:       ₹8.75
  SGST @ 2.5%:       ₹8.75
  Grand Total:       ₹467.50
  ```
- **Thermal Printer (`PrinterService`):**
  On receipt printouts, if GST is present (`gstAmount > 0`), prints Subtotal, CGST, SGST, and Grand Total formatted for 58mm and 80mm paper widths.
- **KDS / Kitchen Print:**
  KDS and Kitchen Tickets remain unchanged (showing item names, notes, and quantities without prices/taxes).

---

## 6. Database Schema Additions (Non-Destructive)

Safe column checks (`ensureColumnExists`) automatically add missing GST columns without dropping or modifying existing production data:

- `products`:
  - `gst_applicable` `TINYINT DEFAULT 0`
  - `gst_rate` `DECIMAL(5,2) DEFAULT 0.00`
- `restaurant_settings` / `shop_settings`:
  - `gst_enabled` `TINYINT DEFAULT 0`
  - `gstin` `VARCHAR(50) NULL`
  - `legal_business_name` `VARCHAR(255) NULL`
  - `business_address` `TEXT NULL`
  - `state` `VARCHAR(100) NULL`
  - `state_code` `VARCHAR(10) NULL`
- `orders`:
  - `subtotal_amount` `DECIMAL(10,2) DEFAULT 0.00`
  - `gst_amount` `DECIMAL(10,2) DEFAULT 0.00`
  - `cgst_amount` `DECIMAL(10,2) DEFAULT 0.00`
  - `sgst_amount` `DECIMAL(10,2) DEFAULT 0.00`
- `order_items`:
  - `taxable_amount` `DECIMAL(10,2) DEFAULT 0.00`
  - `gst_applicable` `TINYINT DEFAULT 0`
  - `gst_rate` `DECIMAL(5,2) DEFAULT 0.00`
  - `gst_amount` `DECIMAL(10,2) DEFAULT 0.00`

---

## 7. Billing Test Examples

### Case 1: Mixed Items (GST 5% + GST 0% + GST 18%)
- **Item A (Pizza):** ₹200.00 (GST 5%) -> Taxable: ₹200.00, GST: ₹10.00, Total: ₹210.00
- **Item B (Cold Drink):** ₹100.00 (GST OFF) -> Taxable: ₹100.00, GST: ₹0.00, Total: ₹100.00
- **Item C (Special Dessert):** ₹150.00 (GST 18%) -> Taxable: ₹150.00, GST: ₹27.00, Total: ₹177.00
- **Order Totals:**
  - Subtotal: ₹450.00
  - Total GST: ₹37.00 (CGST: ₹18.50, SGST: ₹18.50)
  - Grand Total: ₹487.00

### Case 2: GST Billing OFF in Settings
- Same items, but `gst_enabled = false` in restaurant settings.
- **Order Totals:**
  - Subtotal: ₹450.00
  - GST: ₹0.00
  - Grand Total: ₹450.00
