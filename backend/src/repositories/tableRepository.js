const { pool } = require('../config/database');
const { sendNewOrderPushNotification } = require('../utils/fcmService');

function round2(num) {
  return Math.round((Number(num) + Number.EPSILON) * 100) / 100;
}

class TableRepository {
  // Active dine-in order for a table, or null.
  async _findActiveTableOrder(connOrPool, userId, tableNo) {
    const [rows] = await connOrPool.query(
      `SELECT * FROM orders
       WHERE user_id = ? AND table_no = ? AND order_type = 'dine_in' AND status IN ('pending','running')
       ORDER BY id DESC LIMIT 1`,
      [userId, tableNo]
    );
    return rows[0] || null;
  }

  // Pending tables = active dine-in orders, shaped as the Flutter PendingTableModel.
  async getPendingTables(userId) {
    const [orders] = await pool.query(
      `SELECT id, table_no, customer_name, customer_mobile, order_note, total_amount, subtotal_amount, gst_amount, created_at
       FROM orders
       WHERE user_id = ? AND order_type = 'dine_in' AND status IN ('pending','running')
       ORDER BY table_no ASC`,
      [userId]
    );

    return Promise.all(
      orders.map(async (o) => {
        const [items] = await pool.query(
          'SELECT product_id, product_name, unit, qty, price, taxable_amount, gst_applicable, gst_rate, gst_amount, total, note, created_at FROM order_items WHERE order_id = ? ORDER BY id ASC',
          [o.id]
        );
        return {
          order_id: o.id,
          table_no: o.table_no,
          customer_name: o.customer_name || '',
          customer_mobile: o.customer_mobile || '',
          order_note: o.order_note || '',
          subtotal_amount: parseFloat(o.subtotal_amount || o.total_amount || 0),
          gst_amount: parseFloat(o.gst_amount || 0),
          total_amount: parseFloat(o.total_amount || 0),
          items: items.map((i) => ({
            product_id: i.product_id,
            product_name: i.product_name,
            unit: i.unit,
            qty: parseFloat(i.qty),
            price: parseFloat(i.price),
            taxable_amount: parseFloat(i.taxable_amount || i.total || 0),
            gst_applicable: i.gst_applicable == 1 ? 1 : 0,
            gst_rate: parseFloat(i.gst_rate || 0),
            gst_amount: parseFloat(i.gst_amount || 0),
            total: parseFloat(i.total),
            note: i.note || null,
            created_at: i.created_at
          }))
        };
      })
    );
  }

  async saveTableOrder(userId, data) {
    const {
      table_no,
      customer_name,
      customer_mobile,
      order_note,
      total_amount,
      order_status,
      items = [],
      payment_type,
      upi_amount,
      cash_amount
    } = data;

    const isFinal = order_status === 'completed' || order_status === 'dispatched' || order_status === 'cancelled';
    const sessionStatus = order_status === 'running' ? 'running' : (order_status === 'cancelled' ? 'cancelled' : 'pending');
    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      // Check shop GST Billing setting
      const [shopRows] = await connection.query('SELECT gst_enabled FROM restaurant_settings WHERE user_id = ? LIMIT 1', [userId]);
      const shopGstEnabled = shopRows.length > 0 ? (shopRows[0].gst_enabled == 1 || shopRows[0].gst_enabled == '1') : false;

      // Calculate GST Snapshot for each item
      let orderSubtotal = 0;
      let orderGstAmount = 0;
      const processedItems = [];

      for (const item of items) {
        const qty = Number(item.qty != null ? item.qty : (item.quantity != null ? item.quantity : 1));
        const price = Number(item.price || 0);
        // Prefer the client-calculated line total (it accounts for half-plate
        // pricing on fractional quantities); fall back to qty * price.
        const lineTotal = (item.total != null && Number(item.total) > 0) ? Number(item.total) : qty * price;
        const taxableAmount = round2(lineTotal);

        let isItemGstApplicable = 0;
        let itemGstRate = 0.00;
        let itemGstAmount = 0.00;

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

      const active = await this._findActiveTableOrder(connection, userId, table_no);
      let orderId;

      if (active) {
        orderId = active.id;
        let finalStatus = isFinal ? order_status.toLowerCase() : sessionStatus;
        let sql = `UPDATE orders SET customer_name = ?, customer_mobile = ?, order_note = ?, subtotal_amount = ?, gst_amount = ?, cgst_amount = ?, sgst_amount = ?, total_amount = ?, status = ?, order_status = ?`;
        const params = [
          customer_name || 'Walk-in Customer',
          customer_mobile || 'N/A',
          order_note || null,
          orderSubtotal,
          orderGstAmount,
          cgstAmount,
          sgstAmount,
          grandTotal,
          finalStatus,
          finalStatus
        ];
        if (isFinal) {
          sql += ', payment_type = ?, upi_amount = ?, cash_amount = ?';
          params.push(payment_type || 'cash', upi_amount != null ? upi_amount : 0.0, cash_amount != null ? cash_amount : 0.0);
        }
        sql += ' WHERE id = ? AND user_id = ?';
        params.push(orderId, userId);
        await connection.query(sql, params);

        await connection.query('DELETE FROM order_items WHERE order_id = ?', [orderId]);
      } else {
        const [orderResult] = await connection.query(
          `INSERT INTO orders
            (user_id, token_no, table_no, customer_name, customer_mobile, order_note, subtotal_amount, gst_amount, cgst_amount, sgst_amount, total_amount, status, order_type, payment_type, upi_amount, cash_amount, order_date)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'dine_in', ?, ?, ?, NOW())`,
          [
            userId,
            table_no != null ? table_no : 0,
            table_no,
            customer_name || 'Walk-in Customer',
            customer_mobile || 'N/A',
            order_note || null,
            orderSubtotal,
            orderGstAmount,
            cgstAmount,
            sgstAmount,
            grandTotal,
            isFinal ? order_status.toLowerCase() : sessionStatus,
            isFinal ? (payment_type || 'cash') : 'cash',
            isFinal && upi_amount != null ? upi_amount : 0.0,
            isFinal && cash_amount != null ? cash_amount : 0.0
          ]
        );
        orderId = orderResult.insertId;
      }

      for (const item of processedItems) {
        await connection.query(
          `INSERT INTO order_items (order_id, product_id, product_name, qty, unit, price, taxable_amount, gst_applicable, gst_rate, gst_amount, total, note)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            orderId,
            item.productId,
            item.productName,
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

      const tokenNo = String(table_no != null ? table_no : 0);

      sendNewOrderPushNotification(userId, tokenNo, grandTotal).catch((err) => {
        console.error('[FCM] Push trigger failed:', err.message);
      });

      return { orderId, tokenNo, finalized: isFinal, grandTotal, subtotal: orderSubtotal, gstAmount: orderGstAmount };
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  }

  async cancelTableOrder(userId, tableNo) {
    const uids = (Number(userId) === 1 || Number(userId) === 2) ? [1, 2] : [userId];
    const [rows] = await pool.query(
      `SELECT id FROM orders
       WHERE user_id IN (?) AND table_no = ? AND order_type = 'dine_in' AND status IN ('pending','running')
       ORDER BY id DESC`,
      [uids, tableNo]
    );
    if (!rows || rows.length === 0) {
      return { message: 'No active order for this table', cancelled: false };
    }
    const ids = rows.map((r) => r.id);
    await pool.query(
      `UPDATE orders
       SET status = 'cancelled', order_status = 'cancelled', updated_at = NOW()
       WHERE id IN (?)`,
      [ids]
    );
    return { order_ids: ids, cancelled: true };
  }
}

module.exports = new TableRepository();
