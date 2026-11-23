const mysql = require('mysql2/promise');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '../../.env') });

const dbName = process.env.DB_NAME || 'lineless_db';
const dbHost = process.env.DB_HOST || 'localhost';

const pool = mysql.createPool({
  host: dbHost,
  port: parseInt(process.env.DB_PORT || '3306', 10),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: dbName,
  waitForConnections: true,
  connectionLimit: 20,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0
});

async function ensureColumnExists(connection, db, tableName, columnName, columnDef) {
  try {
    const [cols] = await connection.query(
      `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1`,
      [db, tableName, columnName]
    );
    if (cols.length === 0) {
      await connection.query(`ALTER TABLE \`${tableName}\` ADD COLUMN \`${columnName}\` ${columnDef}`);
      console.log(`[DATABASE] Added missing GST/Subcategory column ${tableName}.${columnName}`);
    }
  } catch (err) {
    console.warn(`[DATABASE] Column check for ${tableName}.${columnName} warning:`, err.message);
  }
}

// Safe Table & Column Initialization (Never Destructive)
async function initDatabase() {
  try {
    const connection = await pool.getConnection();

    // Always run non-destructive missing column checks on existing production tables
    await ensureColumnExists(connection, dbName, 'products', 'gst_applicable', 'TINYINT DEFAULT 0');
    await ensureColumnExists(connection, dbName, 'products', 'gst_rate', 'DECIMAL(5, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'products', 'variants', 'TEXT NULL');
    await ensureColumnExists(connection, dbName, 'products', 'deleted_at', 'DATETIME NULL');

    await ensureColumnExists(connection, dbName, 'categories', 'subcategories', 'TEXT NULL');
    await ensureColumnExists(connection, dbName, 'categories', 'deleted_at', 'DATETIME NULL');

    await ensureColumnExists(connection, dbName, 'restaurant_settings', 'gst_enabled', 'TINYINT DEFAULT 0');
    await ensureColumnExists(connection, dbName, 'restaurant_settings', 'gstin', 'VARCHAR(50) NULL');
    await ensureColumnExists(connection, dbName, 'restaurant_settings', 'legal_business_name', 'VARCHAR(255) NULL');
    await ensureColumnExists(connection, dbName, 'restaurant_settings', 'business_address', 'TEXT NULL');
    await ensureColumnExists(connection, dbName, 'restaurant_settings', 'state', 'VARCHAR(100) NULL');
    await ensureColumnExists(connection, dbName, 'restaurant_settings', 'state_code', 'VARCHAR(10) NULL');

    await ensureColumnExists(connection, dbName, 'shop_settings', 'gst_enabled', 'TINYINT DEFAULT 0');
    await ensureColumnExists(connection, dbName, 'shop_settings', 'gstin', 'VARCHAR(50) NULL');
    await ensureColumnExists(connection, dbName, 'shop_settings', 'legal_business_name', 'VARCHAR(255) NULL');
    await ensureColumnExists(connection, dbName, 'shop_settings', 'business_address', 'TEXT NULL');
    await ensureColumnExists(connection, dbName, 'shop_settings', 'state', 'VARCHAR(100) NULL');
    await ensureColumnExists(connection, dbName, 'shop_settings', 'state_code', 'VARCHAR(10) NULL');

    await ensureColumnExists(connection, dbName, 'orders', 'subtotal_amount', 'DECIMAL(10, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'orders', 'gst_amount', 'DECIMAL(10, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'orders', 'cgst_amount', 'DECIMAL(10, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'orders', 'sgst_amount', 'DECIMAL(10, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'orders', 'status', "VARCHAR(50) DEFAULT 'pending'");
    await ensureColumnExists(connection, dbName, 'orders', 'order_status', "VARCHAR(50) DEFAULT 'pending'");
    await ensureColumnExists(connection, dbName, 'orders', 'order_note', "TEXT NULL");
    await ensureColumnExists(connection, dbName, 'orders', 'special_note', "TEXT NULL");

    await ensureColumnExists(connection, dbName, 'order_items', 'taxable_amount', 'DECIMAL(10, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'order_items', 'gst_applicable', 'TINYINT DEFAULT 0');
    await ensureColumnExists(connection, dbName, 'order_items', 'gst_rate', 'DECIMAL(5, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'order_items', 'gst_amount', 'DECIMAL(10, 2) DEFAULT 0.00');
    await ensureColumnExists(connection, dbName, 'order_items', 'qty', 'DECIMAL(10, 2) NULL');
    await ensureColumnExists(connection, dbName, 'order_items', 'quantity', 'DECIMAL(10, 2) NULL');
    // Per-item note (sub-category / customization) so it survives reloads and
    // shows on order details and the printed bill/kitchen copy.
    await ensureColumnExists(connection, dbName, 'order_items', 'note', 'TEXT NULL');

    // Skip full CREATE TABLE statements if DB_INIT_SCHEMA=false
    if (process.env.DB_INIT_SCHEMA === 'false') {
      connection.release();
      console.log('[DATABASE] Column checks completed. Schema creation skipped (DB_INIT_SCHEMA=false).');
      return;
    }

    // First connect without database selected to ensure DB exists
    const rootConn = await mysql.createConnection({
      host: dbHost,
      port: parseInt(process.env.DB_PORT || '3306', 10),
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || ''
    });

    await rootConn.query(`CREATE DATABASE IF NOT EXISTS \`${dbName}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
    await rootConn.end();

    // 1. Users table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        phone VARCHAR(50) NULL,
        role VARCHAR(50) DEFAULT 'admin',
        profile_image VARCHAR(255) NULL,
        profile_banner VARCHAR(255) NULL,
        user_pin VARCHAR(50) NULL,
        slug VARCHAR(255) NULL,
        fcm_token VARCHAR(255) NULL,
        device_id VARCHAR(255) NULL,
        device_type VARCHAR(50) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 2. Shop Settings table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS shop_settings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        shop_open VARCHAR(10) DEFAULT '0',
        morning_start VARCHAR(10) DEFAULT '09:00',
        morning_end VARCHAR(10) DEFAULT '12:00',
        afternoon_start VARCHAR(10) DEFAULT '12:00',
        afternoon_end VARCHAR(10) DEFAULT '17:00',
        evening_start VARCHAR(10) DEFAULT '17:00',
        evening_end VARCHAR(10) DEFAULT '23:00',
        category_display VARCHAR(10) DEFAULT '1',
        generated_code VARCHAR(100) NULL,
        opration_mode_status VARCHAR(50) DEFAULT 'both',
        number_of_tables INT DEFAULT 10,
        gst_enabled TINYINT DEFAULT 0,
        gstin VARCHAR(50) NULL,
        legal_business_name VARCHAR(255) NULL,
        business_address TEXT NULL,
        state VARCHAR(100) NULL,
        state_code VARCHAR(10) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_user_id (user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 3. Categories table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        image VARCHAR(255) NULL,
        status TINYINT DEFAULT 1,
        sort_order INT DEFAULT 0,
        subcategories TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_category_user (user_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 4. Products table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        category_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        description TEXT NULL,
        unit VARCHAR(50) DEFAULT 'PLATE',
        price DECIMAL(10, 2) NOT NULL,
        half_price DECIMAL(10, 2) NULL,
        image VARCHAR(255) NULL,
        status TINYINT DEFAULT 1,
        sort_order INT DEFAULT 0,
        gst_applicable TINYINT DEFAULT 0,
        gst_rate DECIMAL(5, 2) DEFAULT 0.00,
        variants TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_product_user (user_id),
        INDEX idx_product_category (category_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 5. Orders table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        token_no VARCHAR(50) NOT NULL,
        table_no INT NULL,
        customer_name VARCHAR(255) DEFAULT 'Walk-in Customer',
        customer_mobile VARCHAR(50) DEFAULT 'N/A',
        total_amount DECIMAL(10, 2) NOT NULL,
        subtotal_amount DECIMAL(10, 2) DEFAULT 0.00,
        gst_amount DECIMAL(10, 2) DEFAULT 0.00,
        cgst_amount DECIMAL(10, 2) DEFAULT 0.00,
        sgst_amount DECIMAL(10, 2) DEFAULT 0.00,
        order_status VARCHAR(50) DEFAULT 'pending',
        started_at DATETIME NULL,
        order_type VARCHAR(50) DEFAULT 'dine_in',
        payment_type VARCHAR(50) NULL,
        upi_amount DECIMAL(10, 2) DEFAULT 0.00,
        cash_amount DECIMAL(10, 2) DEFAULT 0.00,
        special_note TEXT NULL,
        order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_order_user (user_id),
        INDEX idx_order_status (order_status),
        INDEX idx_order_date (order_date)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 6. Order Items table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        product_id INT NULL,
        product_name VARCHAR(255) NOT NULL,
        quantity DECIMAL(10, 2) NOT NULL,
        unit VARCHAR(50) DEFAULT 'PLATE',
        price DECIMAL(10, 2) NOT NULL,
        taxable_amount DECIMAL(10, 2) DEFAULT 0.00,
        gst_applicable TINYINT DEFAULT 0,
        gst_rate DECIMAL(5, 2) DEFAULT 0.00,
        gst_amount DECIMAL(10, 2) DEFAULT 0.00,
        total DECIMAL(10, 2) NOT NULL,
        note TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_item_order (order_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 7. Pending Tables
    await connection.query(`
      CREATE TABLE IF NOT EXISTS pending_tables (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        table_no INT NOT NULL,
        customer_name VARCHAR(255) NULL,
        customer_mobile VARCHAR(50) NULL,
        order_note TEXT NULL,
        total_amount DECIMAL(10, 2) DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_pending_table (user_id, table_no)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 8. Pending Table Items
    await connection.query(`
      CREATE TABLE IF NOT EXISTS pending_table_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pending_table_id INT NOT NULL,
        product_id INT NOT NULL,
        product_name VARCHAR(255) NOT NULL,
        unit VARCHAR(50) NULL,
        qty DECIMAL(10, 2) NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        total DECIMAL(10, 2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_pending_item (pending_table_id)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    connection.release();
    console.log('[DATABASE] MySQL Schema check/initialization completed.');
  } catch (error) {
    console.error('[DATABASE ERROR] Failed to initialize MySQL database:', error.message);
  }
}

module.exports = {
  pool,
  initDatabase
};
