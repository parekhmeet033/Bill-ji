const { pool } = require('../config/database');
const { sendNewOrderPushNotification } = require('../utils/fcmService');

function round2(num) {
  return Math.round((Number(num) + Number.EPSILON) * 100) / 100;
}

class OrderRepository {
  async getPublicOrderById(orderId) {
    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ? LIMIT 1', [orderId]);
    if (!rows[0]) return null;
    return this._mapOrder(rows[0]);
  }

  async cancelPublicOrder(orderId) {
    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ? LIMIT 1', [orderId]);
    if (!rows[0]) return null;
    const order = rows[0];
    const status = (order.status || '').toLowerCase();
    if (['completed', 'dispatched', 'cancelled'].includes(status)) {
      throw new Error(`Order cannot be cancelled because it is already ${status}`);
    }
    await pool.query("UPDATE orders SET status = 'cancelled' WHERE id = ?", [orderId]);
    return this._mapOrder({ ...order, status: 'cancelled' });
  }

  async editPublicOrder(orderId, payload) {
    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ? LIMIT 1', [orderId]);
    if (!rows[0]) return null;
    const order = rows[0];
    const status = (order.status || '').toLowerCase();
    if (['completed', 'dispatched', 'cancelled'].includes(status)) {
      throw new Error(`Order cannot be edited because it is already ${status}`);
    }

    const { customer_name, customer_mobile, special_note, items = [] } = payload;
    if (!items.length) throw new Error('Cart is empty');

    const userId = order.user_id;
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      let orderSubtotal = 0;
      const processedItems = [];

      for (const item of items) {
        const qty = Number(item.qty || item.quantity || 1);
        const price = Number(item.price || 0);
        const itemTotal = Number(item.total || (qty * price));
        orderSubtotal += itemTotal;

        processedItems.push({
          productId: item.product_id || null,
          productName: item.product_name || item.name || 'Item',
          qty: qty.toString(),
          unit: item.unit || 'PLATE',
          price,
          taxableAmount: itemTotal,
          isItemGstApplicable: 0,
          itemGstRate: 0,
          itemGstAmount: 0,
          itemTotal,
          note: (item.note != null && String(item.note).trim() !== '') ? String(item.note).trim() : null
        });
      }

      const grandTotal = round2(orderSubtotal);

      await connection.query(
        `UPDATE orders SET
          customer_name = ?, customer_mobile = ?, order_note = ?,
          subtotal_amount = ?, total_amount = ?, updated_at = NOW()
         WHERE id = ?`,
        [customer_name || order.customer_name, customer_mobile || order.customer_mobile, special_note || '', orderSubtotal, grandTotal, orderId]
      );

      await connection.query('DELETE FROM order_items WHERE order_id = ?', [orderId]);

      for (const item of processedItems) {
        await connection.query(
          `INSERT INTO order_items (order_id, product_id, product_name, qty, quantity, unit, price, taxable_amount, gst_applicable, gst_rate, gst_amount, total, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            orderId,
            item.productId,
            item.productName,
            item.qty,
            item.qty,
            item.unit,
            item.price,
            item.taxableAmount,
            item.isItemGstApplicable,
            item.itemGstRate,
            item.itemGstAmount,
            item.itemTotal,
            item.note
          ]
        );
      }

      await connection.commit();
      return this.getPublicOrderById(orderId);
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  }

  async getDashboardData(userId) {
    const uids = (Number(userId) === 1 || Number(userId) === 2) ? [1, 2] : [userId];
    const [statsRows] = await pool.query(
      `SELECT
        COUNT(*) AS today_total,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS today_pending,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS today_completed,
        SUM(CASE WHEN status = 'dispatched' THEN 1 ELSE 0 END) AS today_dispatched
       FROM orders
       WHERE user_id IN (?) AND DATE(order_date) = CURDATE() AND status != 'draft'`,
      [uids]
    );

    const stats = statsRows[0] || {};
    const runningToken = await this.getRunningToken(userId);

    const [recentOrdersRows] = await pool.query(
      `SELECT * FROM orders
       WHERE user_id IN (?) AND DATE(order_date) = CURDATE() AND status NOT IN ('dispatched', 'cancelled', 'draft')
       ORDER BY id DESC`,
      [uids]
    );

    const recentOrdersWithItems = await Promise.all(
      recentOrdersRows.map(async (order) => this._mapOrder(order))
    );

    return {
      today_total_orders: parseInt(stats.today_total || 0, 10),
      today_pending_orders: parseInt(stats.today_pending || 0, 10),
      today_completed_orders: parseInt(stats.today_completed || 0, 10),
      today_dispatched_orders: parseInt(stats.today_dispatched || 0, 10),
      running_token: (runningToken != null ? runningToken : 0).toString(),
      recent_orders: recentOrdersWithItems
    };
  }

  async getOrdersList(userId, filters = {}) {
    const page = parseInt(filters.page || 1, 10);
    const limit = parseInt(filters.limit || 15, 10);
    const offset = (page - 1) * limit;

    const uids = (Number(userId) === 1 || Number(userId) === 2) ? [1, 2] : [userId];
    // Never surface in-progress POS drafts in the orders list.
    let whereClause = "WHERE user_id IN (?) AND status != 'draft'";
    const params = [uids];

    // Filter by orderType
    if (filters.orderType && filters.orderType.toLowerCase() !== 'all') {
      const type = filters.orderType.toLowerCase();
      if (type === 'takeaway' || type === 'take_away') {
        whereClause += " AND order_type IN ('take_away', 'takeaway', 'qr')";
      } else if (type === 'dinein' || type === 'dine_in') {
        whereClause += " AND order_type = 'dine_in'";
      } else {
        whereClause += " AND order_type = ?";
        params.push(type);
      }
    }

    // Filter by status
    if (filters.status && filters.status.toLowerCase() !== 'all') {
      const st = filters.status.toLowerCase();
      whereClause += " AND status = ?";
      params.push(st);
    }

    // Filter by search term
    if (filters.search && filters.search.trim() !== '') {
      const searchTerm = `%${filters.search.trim()}%`;
      whereClause += " AND (customer_name LIKE ? OR customer_mobile LIKE ? OR token_no LIKE ? OR CAST(id AS CHAR) LIKE ?)";
      params.push(searchTerm, searchTerm, searchTerm, searchTerm);
    }

    // Filter by startDate & endDate
    if (filters.startDate) {
      whereClause += " AND DATE(order_date) >= ?";
      params.push(filters.startDate);
    }
    if (filters.endDate) {
      whereClause += " AND DATE(order_date) <= ?";
      params.push(filters.endDate);
    }

    // Get total count
    const [countRows] = await pool.query(
      `SELECT COUNT(*) AS total FROM orders ${whereClause}`,
      params
    );
    const total = countRows[0] ? countRows[0].total : 0;
    const lastPage = Math.ceil(total / limit) || 1;

    // Get paginated items
    const [orderRows] = await pool.query(
      `SELECT * FROM orders ${whereClause} ORDER BY id DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset]
    );

    const ordersWithItems = await Promise.all(
      orderRows.map(async (order) => this._mapOrder(order))
    );

    return {
      data: ordersWithItems,
      pagination: {
        currentPage: page,
        lastPage,
        perPage: limit,
        total
      }
    };
  }

  async getAllOrdersRaw(userId) {
    const [rows] = await pool.query(
      `SELECT * FROM orders WHERE user_id = ? AND status != 'draft' ORDER BY id DESC LIMIT 100`,
      [userId]
    );
    return Promise.all(rows.map(async (order) => this._mapOrder(order)));
  }

  async _mapOrder(order) {
    const [items] = await pool.query(
      `SELECT * FROM order_items WHERE order_id = ?`,
      [order.id]
    );
    return {
      id: order.id,
      order_id: order.id,
      token_no: String(order.token_no || ''),
      token_number: String(order.token_no || ''),
      table_no: order.table_no != null ? String(order.table_no) : '',
      customer_name: order.customer_name || 'Walk-in Customer',
      customer_mobile: order.customer_mobile || 'N/A',
      subtotal_amount: parseFloat(order.subtotal_amount || order.total_amount || 0),
      gst_amount: parseFloat(order.gst_amount || 0),
      cgst_amount: parseFloat(order.cgst_amount || 0),
      sgst_amount: parseFloat(order.sgst_amount || 0),
      total_amount: parseFloat(order.total_amount || 0),
      order_date: order.order_date,
      created_at: order.order_date || order.created_at,
      status: order.status,
      special_note: order.order_note || '',
      order_note: order.order_note || '',
      order_type: order.order_type || 'dine_in',
      payment_type: order.payment_type || 'cash',
      upi_amount: parseFloat(order.upi_amount || 0),
      cash_amount: parseFloat(order.cash_amount || 0),
      items: items.map((item) => ({
        product_id: item.product_id,
        product_name: item.product_name,
        name: item.product_name,
        quantity: (item.qty != null ? item.qty : '').toString(),
        qty: (item.qty != null ? item.qty : '').toString(),
        price: parseFloat(item.price),
        taxable_amount: parseFloat(item.taxable_amount != null ? item.taxable_amount : (item.total || 0)),
        gst_applicable: item.gst_applicable == 1 ? 1 : 0,
        gst_rate: parseFloat(item.gst_rate || 0),
        gst_amount: parseFloat(item.gst_amount || 0),
        total: parseFloat(item.total),
        unit: item.unit,
        note: item.note || null
      }))
    };
  }

  async getRunningToken(userId) {
    const uids = (Number(userId) === 1 || Number(userId) === 2) ? [1, 2] : [userId];
    // Only return token when an order is explicitly in 'running' or 'preparing' status
    const [runningRows] = await pool.query(
      `SELECT token_no FROM orders
       WHERE user_id IN (?) AND DATE(order_date) = CURDATE() AND order_type != 'dine_in' AND status IN ('running', 'preparing')
       ORDER BY updated_at DESC, id DESC
       LIMIT 1`,
      [uids]
    );

    if (runningRows.length > 0 && runningRows[0].token_no) {
      return String(runningRows[0].token_no);
    }

    return '0';
  }

  async updateOrderStatus(userId, orderId, status, paymentType, upiAmount, cashAmount) {
    const uids = (Number(userId) === 1 || Number(userId) === 2) ? [1, 2] : [userId];
    let sql = 'UPDATE orders SET status = ?, order_status = ?';
    const params = [status.toLowerCase(), status.toLowerCase()];

    if (paymentType) {
      sql += ', payment_type = ?';
      params.push(paymentType);
    }
    if (upiAmount !== undefined && upiAmount !== null) {
      sql += ', upi_amount = ?';
      params.push(upiAmount);
    }
    if (cashAmount !== undefined && cashAmount !== null) {
      sql += ', cash_amount = ?';
      params.push(cashAmount);
    }

    sql += ' WHERE id = ? AND user_id IN (?)';
    params.push(orderId, uids);

    const [result] = await pool.query(sql, params);
    return result.affectedRows > 0;
  }

  async deleteOrdersByDate(userId, startDate, endDate) {
    const uids = (Number(userId) === 1 || Number(userId) === 2) ? [1, 2] : [userId];
    await pool.query(
      'DELETE FROM orders WHERE user_id IN (?) AND DATE(order_date) >= ? AND DATE(order_date) <= ?',
      [uids, startDate, endDate]
    );
  }

  // The user's single in-progress take-away draft (auto-saved POS cart), or null.
  async _findDraftTakeaway(connOrPool, userId) {
    const [rows] = await connOrPool.query(
      "SELECT * FROM orders WHERE user_id = ? AND order_type = 'take_away' AND status = 'draft' ORDER BY id DESC LIMIT 1",
      [userId]
    );
    return rows[0] || null;
  }

  // The current take-away draft shaped like a normal order (for restoring the
  // POS cart on launch), or null when there is no draft.
  async getDraftPosOrder(userId) {
    const draft = await this._findDraftTakeaway(pool, userId);
    if (!draft) return null;
    return this._mapOrder(draft);
  }

  // Discards the user's in-progress take-away draft (used when the POS order is
  // cancelled), so it won't be restored on the next launch.
  async clearDraftPosOrder(userId) {
    const draft = await this._findDraftTakeaway(pool, userId);
    if (!draft) return false;
    await pool.query('DELETE FROM order_items WHERE order_id = ?', [draft.id]);
    await pool.query("DELETE FROM orders WHERE id = ? AND user_id = ? AND status = 'draft'", [draft.id, userId]);
    return true;
  }

  async createDirectOrder(userId, payload) {
    const {
      customer_name, customer_mobile, special_note,
      order_type = 'take_away', payment_type = null, order_status = 'pending',
      upi_amount = null, cash_amount = null, items = []
    } = payload;

    const laravelType = order_type === 'dine_in' ? 'dine_in' : 'take_away';
    const laravelStatus = (order_status || 'pending').toLowerCase();
    const laravelPayment = payment_type || 'cash';

    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      // Shop-level GST setting (mirrors the dine-in flow) so take-away/QR bills
      // also show GST when it is enabled for the shop and the product.
      const [shopRows] = await connection.query('SELECT gst_enabled FROM restaurant_settings WHERE user_id = ? LIMIT 1', [userId]);
      const shopGstEnabled = shopRows.length > 0 ? (shopRows[0].gst_enabled == 1 || shopRows[0].gst_enabled == '1') : false;

      // A take-away "draft" is the in-progress POS cart (auto-saved before the
      // order is placed). It is excluded from token numbering, dashboards,
      // order lists and reports until it is finalized to 'pending'.
      const isDraft = laravelStatus === 'draft';

      // Only a finalized (non-draft) order consumes a token number.
      let tokenNo = 0;
      if (!isDraft) {
        const [maxTokenRows] = await connection.query(
          "SELECT MAX(CAST(token_no AS UNSIGNED)) AS max_token FROM orders WHERE user_id = ? AND DATE(order_date) = CURDATE() AND order_type != 'dine_in' AND status != 'draft'",
          [userId]
        );
        tokenNo = (maxTokenRows[0].max_token || 0) + 1;
      }

      let orderSubtotal = 0;
      let orderGstAmount = 0;
      const processedItems = [];

      for (const item of items) {
        const qty = Number(item.qty || item.quantity || 1);
        const price = Number(item.price || 0);
        // Prefer the line total the client calculated: it accounts for
        // half-plate pricing on fractional quantities (e.g. 2.5 plates), which
        // a plain qty * price would miss. Fall back to qty * price.
        const lineTotal = (item.total != null && Number(item.total) > 0) ? Number(item.total) : qty * price;
        const taxableAmount = round2(lineTotal);
        let isItemGstApplicable = 0;
        let itemGstRate = 0;
        let itemGstAmount = 0;

        if (shopGstEnabled) {
          let prodGstApplicable = item.gst_applicable;
          let prodGstRate = item.gst_rate;
          if (item.product_id && (prodGstApplicable === undefined || prodGstRate === undefined)) {
            const [pRows] = await connection.query('SELECT gst_applicable, gst_rate FROM products WHERE id = ? LIMIT 1', [item.product_id]);
            if (pRows.length > 0) {
              prodGstApplicable = pRows[0].gst_applicable;
              prodGstRate = pRows[0].gst_rate;
            }
          }
          if (prodGstApplicable == 1 || prodGstApplicable == '1' || prodGstApplicable === true) {
            isItemGstApplicable = 1;
            itemGstRate = parseFloat(prodGstRate || 0);
            itemGstAmount = round2(taxableAmount * (itemGstRate / 100));
          }
        }

        const itemTotal = round2(taxableAmount + itemGstAmount);
        orderSubtotal = round2(orderSubtotal + taxableAmount);
        orderGstAmount = round2(orderGstAmount + itemGstAmount);

        processedItems.push({
          productId: item.product_id || null,
          productName: item.product_name || item.name || 'Item',
          qty: qty.toString(),
          unit: item.unit || 'PLATE',
          price,
          taxableAmount,
          isItemGstApplicable,
          itemGstRate,
          itemGstAmount,
          itemTotal,
          note: (item.note != null && String(item.note).trim() !== '') ? String(item.note).trim() : null
        });
      }

      const grandTotal = round2(orderSubtotal + orderGstAmount);
      const cgstAmount = round2(orderGstAmount / 2);
      const sgstAmount = round2(orderGstAmount / 2);

      // Upsert the user's single take-away draft: while building the POS cart
      // every auto-save updates the same row; placing the order promotes that
      // draft to 'pending' (a real order). Only one draft exists per user.
      const existingDraft = await this._findDraftTakeaway(connection, userId);
      let orderId;
      if (existingDraft) {
        orderId = existingDraft.id;
        // Keep the draft's token placeholder until it is finalized; when
        // finalizing (non-draft), assign the freshly computed token number.
        const finalToken = isDraft ? (existingDraft.token_no || 0) : tokenNo;
        await connection.query(
          `UPDATE orders SET token_no = ?, customer_name = ?, customer_mobile = ?, order_note = ?,
             subtotal_amount = ?, gst_amount = ?, cgst_amount = ?, sgst_amount = ?, total_amount = ?,
             status = ?, order_type = ?, payment_type = ?, upi_amount = ?, cash_amount = ?
           WHERE id = ? AND user_id = ?`,
          [
            finalToken,
            customer_name || 'Walk-in Customer',
            customer_mobile || 'N/A',
            special_note || null,
            orderSubtotal, orderGstAmount, cgstAmount, sgstAmount, grandTotal,
            laravelStatus, laravelType, laravelPayment,
            upi_amount != null ? upi_amount : 0,
            cash_amount != null ? cash_amount : 0,
            orderId, userId
          ]
        );
        tokenNo = finalToken;
        await connection.query('DELETE FROM order_items WHERE order_id = ?', [orderId]);
      } else {
        const [orderResult] = await connection.query(
          `INSERT INTO orders
            (user_id, token_no, table_no, customer_name, customer_mobile, order_note, subtotal_amount, gst_amount, cgst_amount, sgst_amount, total_amount, status, order_type, payment_type, upi_amount, cash_amount, order_date)
           VALUES (?, ?, NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())`,
          [
            userId, tokenNo,
            customer_name || 'Walk-in Customer',
            customer_mobile || 'N/A',
            special_note || null,
            orderSubtotal, orderGstAmount, cgstAmount, sgstAmount, grandTotal,
            laravelStatus, laravelType, laravelPayment,
            upi_amount != null ? upi_amount : 0,
            cash_amount != null ? cash_amount : 0
          ]
        );
        orderId = orderResult.insertId;
      }

      for (const item of processedItems) {
        await connection.query(
          `INSERT INTO order_items (order_id, product_id, product_name, qty, quantity, unit, price, taxable_amount, gst_applicable, gst_rate, gst_amount, total, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            orderId,
            item.productId,
            item.productName,
            item.qty,
            item.qty,
            item.unit,
            item.price,
            item.taxableAmount,
            item.isItemGstApplicable,
            item.itemGstRate,
            item.itemGstAmount,
            item.itemTotal,
            item.note
          ]
        );
      }

      await connection.commit();

      // Don't notify/print for an in-progress draft — only for a real order.
      if (!isDraft) {
        sendNewOrderPushNotification(userId, tokenNo, grandTotal).catch((err) => {
          console.error('[FCM] Push trigger failed:', err.message);
        });
      }

      return { orderId, tokenNo: tokenNo.toString(), total: grandTotal, subtotal: orderSubtotal, gstAmount: orderGstAmount, draft: isDraft };
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  }

  async getReportsAnalytics(userId, filters = {}) {
    const startDate = filters.startDate;
    const endDate = filters.endDate;
    const isRange = !!(startDate && endDate);

    if (isRange) {
      // Scope the summary to the selected date range (drafts excluded). Only
      // the range-based figures are meaningful here, so the today/weekly fields
      // mirror the range totals (the app relabels the tiles in range mode).
      const [rows] = await pool.query(
        `SELECT
          SUM(CASE WHEN status IN ('completed', 'dispatched') THEN total_amount ELSE 0 END) AS range_revenue,
          SUM(CASE WHEN status != 'draft' THEN 1 ELSE 0 END) AS range_orders,
          SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS orders_cancelled,
          SUM(CASE WHEN status IN ('completed', 'dispatched') THEN upi_amount ELSE 0 END) AS range_upi,
          SUM(CASE WHEN status IN ('completed', 'dispatched') THEN cash_amount ELSE 0 END) AS range_cash
         FROM orders
         WHERE user_id = ? AND status != 'draft' AND DATE(order_date) >= ? AND DATE(order_date) <= ?`,
        [userId, startDate, endDate]
      );
      const d = rows[0] || {};
      const rangeRevenue = parseFloat(d.range_revenue || 0);
      const rangeOrders = parseInt(d.range_orders || 0, 10);
      const rangeUpi = parseFloat(d.range_upi || 0);
      const rangeCash = parseFloat(d.range_cash || 0);
      return {
        today_revenue: rangeRevenue,
        today_total_orders: rangeOrders,
        today_pending_orders: 0,
        today_completed_orders: 0,
        today_dispatched_orders: 0,
        total_sales: rangeRevenue,
        total_orders: rangeOrders,
        orders_cancelled: parseInt(d.orders_cancelled || 0, 10),
        weekly_sales: rangeRevenue,
        today_upi_payment: rangeUpi,
        today_cash_payment: rangeCash,
        total_upi_sales: rangeUpi,
        total_cash_sales: rangeCash
      };
    }

    const [revenueRows] = await pool.query(
      `SELECT
        SUM(CASE WHEN DATE(order_date) = CURDATE() AND status IN ('completed', 'dispatched') THEN total_amount ELSE 0 END) AS today_revenue,
        SUM(CASE WHEN status IN ('completed', 'dispatched') THEN total_amount ELSE 0 END) AS total_sales,
        SUM(CASE WHEN status != 'draft' THEN 1 ELSE 0 END) AS total_orders,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS orders_cancelled,
        SUM(CASE WHEN order_date >= DATE_SUB(NOW(), INTERVAL 7 DAY) AND status IN ('completed', 'dispatched') THEN total_amount ELSE 0 END) AS weekly_sales,
        SUM(CASE WHEN DATE(order_date) = CURDATE() AND status IN ('completed', 'dispatched') THEN upi_amount ELSE 0 END) AS today_upi_payment,
        SUM(CASE WHEN DATE(order_date) = CURDATE() AND status IN ('completed', 'dispatched') THEN cash_amount ELSE 0 END) AS today_cash_payment,
        SUM(CASE WHEN status IN ('completed', 'dispatched') THEN upi_amount ELSE 0 END) AS total_upi_sales,
        SUM(CASE WHEN status IN ('completed', 'dispatched') THEN cash_amount ELSE 0 END) AS total_cash_sales
       FROM orders
       WHERE user_id = ? AND status != 'draft'`,
      [userId]
    );

    const data = revenueRows[0] || {};

    return {
      today_revenue: parseFloat(data.today_revenue || 0),
      today_total_orders: parseInt(data.total_orders || 0, 10),
      today_pending_orders: parseInt(data.orders_cancelled || 0, 10),
      today_completed_orders: parseFloat(data.weekly_sales || 0),
      today_dispatched_orders: parseFloat(data.today_upi_payment || 0),
      total_sales: parseFloat(data.total_sales || 0),
      total_orders: parseInt(data.total_orders || 0, 10),
      orders_cancelled: parseInt(data.orders_cancelled || 0, 10),
      weekly_sales: parseFloat(data.weekly_sales || 0),
      today_upi_payment: parseFloat(data.today_upi_payment || 0),
      today_cash_payment: parseFloat(data.today_cash_payment || 0),
      total_upi_sales: parseFloat(data.total_upi_sales || 0),
      total_cash_sales: parseFloat(data.total_cash_sales || 0)
    };
  }
}

module.exports = new OrderRepository();
