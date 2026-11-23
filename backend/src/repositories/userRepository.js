const { pool } = require('../config/database');
const logger = require('../utils/logger');

class UserRepository {
  async findByEmail(email) {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
    return rows[0] || null;
  }

  async findById(id) {
    const [rows] = await pool.query('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
    return rows[0] || null;
  }

  async updateDeviceAndFcmToken(userId, deviceId, deviceType, fcmToken) {
    if (!deviceId) return;
    try {
      const [existing] = await pool.query(
        'SELECT id FROM user_devices WHERE user_id = ? AND device_id = ? LIMIT 1',
        [userId, deviceId]
      );
      if (existing.length > 0) {
        await pool.query(
          'UPDATE user_devices SET device_type = ?, fcm_token = ?, updated_at = NOW() WHERE id = ?',
          [deviceType || null, fcmToken || null, existing[0].id]
        );
      } else {
        await pool.query(
          'INSERT INTO user_devices (user_id, device_id, device_type, fcm_token, created_at, updated_at) VALUES (?, ?, ?, ?, NOW(), NOW())',
          [userId, deviceId, deviceType || null, fcmToken || null]
        );
      }
    } catch (err) {
      logger.warn(`[AUTH] Device registration skipped (${err.code || 'error'}).`);
    }
  }

  async updatePin(userId, newPin) {
    await pool.query('UPDATE users SET user_pin = ? WHERE id = ?', [newPin, userId]);
  }

  async createUser(userData) {
    const { name, email, password, phone, role } = userData;
    const [result] = await pool.query(
      'INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, ?)',
      [name, email, password, phone || null, role || 'admin']
    );
    return result.insertId;
  }

  // --- Admin Panel methods ---

  async getAllUsers(search = '') {
    const cols = "id, name, email, phone, role, slug, status, " +
      "DATE_FORMAT(plan_start_date, '%Y-%m-%d') AS plan_start_date, " +
      "DATE_FORMAT(plan_end_date, '%Y-%m-%d') AS plan_end_date, " +
      "profile_image, created_at, updated_at";
    if (search && search.trim()) {
      const like = `%${search.trim()}%`;
      const [rows] = await pool.query(
        `SELECT ${cols} FROM users WHERE name LIKE ? OR email LIKE ? OR phone LIKE ? ORDER BY id ASC`,
        [like, like, like]
      );
      return rows;
    }
    const [rows] = await pool.query(`SELECT ${cols} FROM users ORDER BY id ASC`);
    return rows;
  }

  async countUsers() {
    const [[row]] = await pool.query('SELECT COUNT(*) AS total FROM users');
    return row.total;
  }

  async updateUser(id, fields) {
    const allowed = ['name', 'email', 'phone', 'role', 'password', 'slug', 'status', 'plan_start_date', 'plan_end_date'];
    const sets = [];
    const values = [];
    for (const key of allowed) {
      if (fields[key] !== undefined) {
        sets.push(`${key} = ?`);
        values.push(fields[key]);
      }
    }
    if (sets.length === 0) return 0;
    values.push(id);
    const [result] = await pool.query(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`, values);
    return result.affectedRows;
  }

  async deleteUser(id) {
    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [id]);
    return result.affectedRows;
  }

  async getAdminDashboardStats() {
    const [[shops]] = await pool.query(
      `SELECT
        COUNT(*) AS total_shops,
        SUM(CASE WHEN status = 1 THEN 1 ELSE 0 END) AS active_shops,
        SUM(CASE WHEN plan_end_date IS NOT NULL AND plan_end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN 1 ELSE 0 END) AS expiring_soon,
        SUM(CASE WHEN plan_end_date IS NOT NULL AND plan_end_date < CURDATE() THEN 1 ELSE 0 END) AS expired
       FROM users`
    );
    const [[orders]] = await pool.query(
      `SELECT
        COUNT(*) AS total_orders,
        SUM(CASE WHEN DATE(order_date) = CURDATE() THEN 1 ELSE 0 END) AS today_orders,
        COALESCE(SUM(CASE WHEN status IN ('completed','dispatched') THEN total_amount ELSE 0 END), 0) AS total_revenue
       FROM orders`
    );
    const [recent] = await pool.query(
      `SELECT id, name, email, status, DATE_FORMAT(plan_end_date, '%Y-%m-%d') AS plan_end_date, created_at
       FROM users ORDER BY id DESC LIMIT 5`
    );
    return {
      total_shops: Number(shops.total_shops || 0),
      active_shops: Number(shops.active_shops || 0),
      inactive_shops: Number(shops.total_shops || 0) - Number(shops.active_shops || 0),
      expiring_soon: Number(shops.expiring_soon || 0),
      expired: Number(shops.expired || 0),
      total_orders: Number(orders.total_orders || 0),
      today_orders: Number(orders.today_orders || 0),
      total_revenue: Number(orders.total_revenue || 0),
      recent_shops: recent
    };
  }

  async getShopBySlug(slug) {
    const [rows] = await pool.query('SELECT id, name, slug, status FROM users WHERE slug = ? LIMIT 1', [slug]);
    const user = rows[0];
    if (!user) return null;
    const [s] = await pool.query(
      `SELECT generated_code, number_of_tables, opration_mode_status, shop_open, category_display,
              morning_start, morning_end, afternoon_start, afternoon_end, evening_start, evening_end,
              gst_enabled, gstin, legal_business_name, business_address, state, state_code
       FROM restaurant_settings WHERE user_id = ? LIMIT 1`,
      [user.id]
    );
    user.settings = s[0] || {};
    return user;
  }
}

module.exports = new UserRepository();
