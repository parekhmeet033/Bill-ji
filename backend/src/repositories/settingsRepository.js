const { pool } = require('../config/database');

// Settings live in the Laravel `restaurant_settings` table (one row per user).
const SETTINGS_TABLE = 'restaurant_settings';

class SettingsRepository {
  async getByUserId(userId) {
    const [rows] = await pool.query(`SELECT * FROM ${SETTINGS_TABLE} WHERE user_id = ? LIMIT 1`, [userId]);
    if (rows.length === 0) {
      return {
        user_id: userId,
        shop_open: '0',
        morning_start: '09:00:00',
        morning_end: '12:00:00',
        afternoon_start: '12:00:00',
        afternoon_end: '17:00:00',
        evening_start: '17:00:00',
        evening_end: '22:00:00',
        category_display: '1',
        generated_code: '',
        opration_mode_status: 'both',
        number_of_tables: 10,
        gst_enabled: 0,
        gstin: '',
        legal_business_name: '',
        business_address: '',
        state: '',
        state_code: ''
      };
    }
    const row = rows[0];
    row.gst_enabled = row.gst_enabled != null ? (row.gst_enabled == 1 || row.gst_enabled == '1' ? 1 : 0) : 0;
    return row;
  }

  async updateByUserId(userId, settingsData) {
    const {
      shop_open,
      morning_start,
      morning_end,
      afternoon_start,
      afternoon_end,
      evening_start,
      evening_end,
      category_display,
      generated_code,
      opration_mode_status,
      number_of_tables,
      gst_enabled,
      gstin,
      legal_business_name,
      business_address,
      state,
      state_code
    } = settingsData;

    const [existing] = await pool.query(`SELECT id FROM ${SETTINGS_TABLE} WHERE user_id = ? LIMIT 1`, [userId]);

    if (existing.length === 0) {
      await pool.query(
        `INSERT INTO ${SETTINGS_TABLE}
          (user_id, shop_open, morning_start, morning_end, afternoon_start, afternoon_end, evening_start, evening_end, category_display, generated_code, opration_mode_status, number_of_tables, gst_enabled, gstin, legal_business_name, business_address, state, state_code)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          shop_open !== undefined && shop_open !== null ? shop_open : '0',
          morning_start || '09:00:00',
          morning_end || '12:00:00',
          afternoon_start || '12:00:00',
          afternoon_end || '17:00:00',
          evening_start || '17:00:00',
          evening_end || '22:00:00',
          category_display !== undefined && category_display !== null ? category_display : '1',
          generated_code || null,
          opration_mode_status || 'both',
          number_of_tables || 10,
          gst_enabled !== undefined ? (gst_enabled == 1 || gst_enabled == '1' || gst_enabled === true ? 1 : 0) : 0,
          gstin || null,
          legal_business_name || null,
          business_address || null,
          state || null,
          state_code || null
        ]
      );
    } else {
      await pool.query(
        `UPDATE ${SETTINGS_TABLE} SET
          shop_open = COALESCE(?, shop_open),
          morning_start = COALESCE(?, morning_start),
          morning_end = COALESCE(?, morning_end),
          afternoon_start = COALESCE(?, afternoon_start),
          afternoon_end = COALESCE(?, afternoon_end),
          evening_start = COALESCE(?, evening_start),
          evening_end = COALESCE(?, evening_end),
          category_display = COALESCE(?, category_display),
          generated_code = COALESCE(?, generated_code),
          opration_mode_status = COALESCE(?, opration_mode_status),
          number_of_tables = COALESCE(?, number_of_tables),
          gst_enabled = COALESCE(?, gst_enabled),
          gstin = COALESCE(?, gstin),
          legal_business_name = COALESCE(?, legal_business_name),
          business_address = COALESCE(?, business_address),
          state = COALESCE(?, state),
          state_code = COALESCE(?, state_code)
         WHERE user_id = ?`,
        [
          shop_open !== undefined ? shop_open : null,
          morning_start !== undefined ? morning_start : null,
          morning_end !== undefined ? morning_end : null,
          afternoon_start !== undefined ? afternoon_start : null,
          afternoon_end !== undefined ? afternoon_end : null,
          evening_start !== undefined ? evening_start : null,
          evening_end !== undefined ? evening_end : null,
          category_display !== undefined ? category_display : null,
          generated_code !== undefined ? generated_code : null,
          opration_mode_status !== undefined ? opration_mode_status : null,
          number_of_tables !== undefined ? number_of_tables : null,
          gst_enabled !== undefined ? (gst_enabled == 1 || gst_enabled == '1' || gst_enabled === true ? 1 : 0) : null,
          gstin !== undefined ? gstin : null,
          legal_business_name !== undefined ? legal_business_name : null,
          business_address !== undefined ? business_address : null,
          state !== undefined ? state : null,
          state_code !== undefined ? state_code : null,
          userId
        ]
      );
    }

    return this.getByUserId(userId);
  }
}

module.exports = new SettingsRepository();
