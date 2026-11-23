const { pool } = require('../config/database');

function parseVariants(raw) {
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return [];
  }
}

/**
 * Returns the localized name for a row using name_hi / name_gu columns when
 * present, otherwise falls back to the base `name`. Safe even if the localized
 * columns don't exist in the DB (undefined -> English fallback).
 */
function localizeName(row, lang, key = 'name') {
  if (!row || lang === 'en') return row ? row[key] : undefined;
  const value = row[`${key}_${lang}`];
  return value !== undefined && value !== null && value !== '' ? value : row[key];
}

class MenuRepository {
  // --- Categories ---
  async getCategories(userId, lang = 'en') {
    // Migrate legacy 'Customization' name to 'New Dish'
    await pool.query(
      "UPDATE categories SET name = 'New Dish' WHERE user_id = ? AND LOWER(TRIM(name)) = 'customization'",
      [userId]
    );

    let [rows] = await pool.query(
      `SELECT c.*,
        (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id AND p.deleted_at IS NULL) AS products_count
       FROM categories c
       WHERE c.user_id = ?
       ORDER BY c.sort_order ASC, c.id ASC`,
      [userId]
    );

    let newDishCat = rows.find((c) => c.name && c.name.trim().toLowerCase() === 'new dish');

    // Ensure a default "New Dish" category exists for every user
    if (!newDishCat) {
      const defaultSubcategories = JSON.stringify([
        { name: 'Regular', price: 0 },
        { name: 'Half', price: 0 },
        { name: 'Full', price: 0 },
        { name: 'Extra Cheese', price: 30 },
        { name: 'Special Paneer', price: 50 }
      ]);

      const [maxOrder] = await pool.query('SELECT MAX(sort_order) AS max_order FROM categories WHERE user_id = ?', [userId]);
      const sortOrder = (maxOrder[0].max_order || 0) + 1;

      const [result] = await pool.query(
        'INSERT INTO categories (user_id, name, image, status, sort_order, subcategories) VALUES (?, ?, NULL, 1, ?, ?)',
        [userId, 'New Dish', sortOrder, defaultSubcategories]
      );

      const catId = result.insertId;

      // Seed a default "New Dish" product so the category is never empty
      await pool.query(
        'INSERT INTO products (user_id, category_id, name, description, unit, price, status, sort_order) VALUES (?, ?, ?, ?, ?, ?, 1, 1)',
        [userId, catId, 'New Dish', 'Custom dish item', 'PLATE', 100.00]
      );

      [rows] = await pool.query(
        `SELECT c.*,
          (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id AND p.deleted_at IS NULL) AS products_count
         FROM categories c
         WHERE c.user_id = ?
         ORDER BY c.sort_order ASC, c.id ASC`,
        [userId]
      );
    } else {
      // Check if existing "New Dish" category has 0 products
      const [pCountRows] = await pool.query(
        'SELECT COUNT(*) AS total FROM products WHERE category_id = ? AND user_id = ? AND deleted_at IS NULL',
        [newDishCat.id, userId]
      );
      if (pCountRows[0].total === 0) {
        await pool.query(
          'INSERT INTO products (user_id, category_id, name, description, unit, price, status, sort_order) VALUES (?, ?, ?, ?, ?, ?, 1, 1)',
          [userId, newDishCat.id, 'New Dish', 'Custom dish item', 'PLATE', 100.00]
        );

        [rows] = await pool.query(
          `SELECT c.*,
            (SELECT COUNT(*) FROM products p WHERE p.category_id = c.id AND p.deleted_at IS NULL) AS products_count
           FROM categories c
           WHERE c.user_id = ?
           ORDER BY c.sort_order ASC, c.id ASC`,
          [userId]
        );
      }
    }

    return rows.map((r) => ({
      ...r,
      name: localizeName(r, lang),
      subcategories: parseVariants(r.subcategories)
    }));
  }

  async addCategory(userId, name, image, subcategories) {
    const [maxOrder] = await pool.query('SELECT MAX(sort_order) AS max_order FROM categories WHERE user_id = ?', [userId]);
    const sortOrder = (maxOrder[0].max_order || 0) + 1;
    const subcatStr = typeof subcategories === 'string' ? subcategories : JSON.stringify(parseVariants(subcategories));

    const [result] = await pool.query(
      'INSERT INTO categories (user_id, name, image, status, sort_order, subcategories) VALUES (?, ?, ?, 1, ?, ?)',
      [userId, name, image || null, sortOrder, subcatStr]
    );
    return result.insertId;
  }

  async updateCategory(userId, categoryId, name, image, subcategories) {
    let sql = 'UPDATE categories SET name = ?';
    const params = [name];

    if (image !== undefined && image !== null) {
      sql += ', image = ?';
      params.push(image);
    }

    if (subcategories !== undefined && subcategories !== null) {
      const subcatStr = typeof subcategories === 'string' ? subcategories : JSON.stringify(parseVariants(subcategories));
      sql += ', subcategories = ?';
      params.push(subcatStr);
    }

    sql += ' WHERE id = ? AND user_id = ?';
    params.push(categoryId, userId);

    await pool.query(sql, params);
  }

  async deleteCategory(userId, categoryId) {
    await pool.query('DELETE FROM categories WHERE id = ? AND user_id = ?', [categoryId, userId]);
  }

  async reorderCategories(userId, categoryIds) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();
      for (let i = 0; i < categoryIds.length; i++) {
        const catId = categoryIds[i];
        await connection.query(
          'UPDATE categories SET sort_order = ? WHERE id = ? AND user_id = ?',
          [i + 1, catId, userId]
        );
      }
      await connection.commit();
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  }

  // --- Menu Products ---
  async getProducts(userId, lang = 'en') {
    const [rows] = await pool.query(
      `SELECT p.*, c.name AS category_name, c.image AS category_image
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.user_id = ? AND p.deleted_at IS NULL
       ORDER BY p.sort_order ASC, p.id DESC`,
      [userId]
    );
    return rows.map((r) => ({
      ...r,
      name: localizeName(r, lang),
      variants: parseVariants(r.variants)
    }));
  }

  async getProductById(userId, productId) {
    const [rows] = await pool.query(
      `SELECT p.*, c.name AS category_name, c.image AS category_image
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = ? AND p.user_id = ? AND p.deleted_at IS NULL LIMIT 1`,
      [productId, userId]
    );
    if (!rows[0]) return null;
    return {
      ...rows[0],
      variants: parseVariants(rows[0].variants)
    };
  }

  async addProduct(userId, productData) {
    const { category_id, name, description, unit, price, half_price, image, gst_applicable, gst_rate, variants } = productData;
    const [maxOrder] = await pool.query('SELECT MAX(sort_order) AS max_order FROM products WHERE user_id = ?', [userId]);
    const sortOrder = (maxOrder[0].max_order || 0) + 1;

    const isGstApplicable = (gst_applicable == 1 || gst_applicable == '1' || gst_applicable === true) ? 1 : 0;
    const rate = isGstApplicable ? parseFloat(gst_rate || 0) : 0.00;
    const variantsStr = typeof variants === 'string' ? variants : JSON.stringify(parseVariants(variants));

    const [result] = await pool.query(
      `INSERT INTO products (user_id, category_id, name, description, unit, price, half_price, image, status, sort_order, gst_applicable, gst_rate, variants)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?)`,
      [userId, category_id, name, description || null, unit || 'PLATE', price, half_price || null, image || null, sortOrder, isGstApplicable, rate, variantsStr]
    );

    return this.getProductById(userId, result.insertId);
  }

  async updateProduct(userId, productId, productData) {
    const { category_id, name, description, unit, price, half_price, image, gst_applicable, gst_rate, variants } = productData;

    const isGstApplicable = (gst_applicable == 1 || gst_applicable == '1' || gst_applicable === true) ? 1 : 0;
    const rate = isGstApplicable ? parseFloat(gst_rate || 0) : 0.00;
    const variantsStr = typeof variants === 'string' ? variants : JSON.stringify(parseVariants(variants));

    let sql = 'UPDATE products SET category_id = ?, name = ?, unit = ?, price = ?, description = ?, half_price = ?, gst_applicable = ?, gst_rate = ?, variants = ?';
    const params = [category_id, name, unit || 'PLATE', price, description || null, half_price || null, isGstApplicable, rate, variantsStr];

    if (image) {
      sql += ', image = ?';
      params.push(image);
    }

    sql += ' WHERE id = ? AND user_id = ?';
    params.push(productId, userId);

    await pool.query(sql, params);
    return this.getProductById(userId, productId);
  }

  async updateProductStatus(userId, productId, status) {
    await pool.query('UPDATE products SET status = ? WHERE id = ? AND user_id = ?', [status, productId, userId]);
  }

  async deleteProduct(userId, productId) {
    await pool.query('UPDATE products SET deleted_at = NOW() WHERE id = ? AND user_id = ? AND deleted_at IS NULL', [productId, userId]);
  }

  async reorderMenu(userId, categoryId, productIds) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();
      for (let i = 0; i < productIds.length; i++) {
        const prodId = productIds[i];
        await connection.query(
          'UPDATE products SET sort_order = ? WHERE id = ? AND category_id = ? AND user_id = ?',
          [i + 1, prodId, categoryId, userId]
        );
      }
      await connection.commit();
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  }

  async getTableProducts(userId, lang = 'en') {
    const categories = await this.getCategories(userId, lang);

    // SELECT * so name_hi / name_gu come along when those columns exist.
    const [products] = await pool.query(
      'SELECT * FROM products WHERE user_id = ? AND status = 1 AND deleted_at IS NULL ORDER BY sort_order ASC, id DESC',
      [userId]
    );

    return categories.map((cat) => ({
      id: cat.id,
      name: cat.name,
      image: cat.image,
      subcategories: cat.subcategories || [],
      products: products
        .filter((p) => p.category_id === cat.id)
        .map((p) => ({
          ...p,
          name: localizeName(p, lang),
          variants: parseVariants(p.variants)
        }))
    }));
  }
}

module.exports = new MenuRepository();
