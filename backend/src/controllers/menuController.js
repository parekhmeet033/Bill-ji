const menuService = require('../services/menuService');
const { successResponse, errorResponse } = require('../utils/responseFormatter');

class MenuController {
  // Categories
  async getCategoryList(req, res, next) {
    try {
      const categories = await menuService.getCategoryList(req.user.id, req.lang);
      return successResponse(res, 'Categories fetched', categories);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch categories', 400);
    }
  }

  async addCategory(req, res, next) {
    try {
      const { name, subcategories } = req.body;
      if (!name) return errorResponse(res, 'Category name is required', 400);

      await menuService.addCategory(req.user.id, name, req.file, subcategories);
      return successResponse(res, 'Category added successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to add category', 400);
    }
  }

  async updateCategory(req, res, next) {
    try {
      const { id, name, subcategories } = req.body;
      if (!id || !name) return errorResponse(res, 'Category ID and name are required', 400);

      await menuService.updateCategory(req.user.id, id, name, req.file, subcategories);
      return successResponse(res, 'Category updated successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to update category', 400);
    }
  }

  async deleteCategory(req, res, next) {
    try {
      const { id } = req.body;
      if (!id) return errorResponse(res, 'Category ID is required', 400);

      await menuService.deleteCategory(req.user.id, id);
      return successResponse(res, 'Category deleted successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to delete category', 400);
    }
  }

  async reorderCategories(req, res, next) {
    try {
      const { categories } = req.body;
      if (!Array.isArray(categories)) return errorResponse(res, 'Categories array required', 400);

      const ids = categories.map((c) => (typeof c === 'object' ? c.id : c));
      await menuService.reorderCategories(req.user.id, ids);
      return successResponse(res, 'Categories reordered successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to reorder categories', 400);
    }
  }

  // Menu Products
  async getMenuList(req, res, next) {
    try {
      const products = await menuService.getMenuList(req.user.id, req.lang);
      return res.status(200).json({
        status: true,
        success: true,
        message: 'Menu items fetched',
        product: products
      });
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch menu items', 400);
    }
  }

  async addMenuItem(req, res, next) {
    try {
      const { category_id, name, unit, price, description, half_price, gst_applicable, gst_rate, variants } = req.body;
      if (!category_id || !name || !price) {
        return errorResponse(res, 'category_id, name, and price are required', 400);
      }

      const product = await menuService.addMenuItem(
        req.user.id,
        { category_id, name, unit, price, description, half_price, gst_applicable, gst_rate, variants },
        req.file
      );

      return successResponse(res, 'Product added successfully', product);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to add product', 400);
    }
  }

  async updateMenuItem(req, res, next) {
    try {
      const { id, category_id, name, unit, price, description, half_price, gst_applicable, gst_rate, variants } = req.body;
      if (!id) return errorResponse(res, 'Product ID is required', 400);

      const product = await menuService.updateMenuItem(
        req.user.id,
        id,
        { category_id, name, unit, price, description, half_price, gst_applicable, gst_rate, variants },
        req.file
      );

      return successResponse(res, 'Product updated successfully', product);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to update product', 400);
    }
  }

  async updateMenuStatus(req, res, next) {
    try {
      const { product_id, status } = req.body;
      if (!product_id || status === undefined) return errorResponse(res, 'product_id and status are required', 400);

      await menuService.updateMenuStatus(req.user.id, product_id, status);
      return successResponse(res, 'Status updated successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to update menu status', 400);
    }
  }

  async deleteMenuItem(req, res, next) {
    try {
      const { product_id } = req.body;
      if (!product_id) return errorResponse(res, 'product_id is required', 400);

      await menuService.deleteMenuItem(req.user.id, product_id);
      return successResponse(res, 'Product deleted successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to delete product', 400);
    }
  }

  async reorderMenu(req, res, next) {
    try {
      const { category_id, product_ids } = req.body;
      if (!category_id || !Array.isArray(product_ids)) {
        return errorResponse(res, 'category_id and product_ids array required', 400);
      }

      const ids = product_ids.map((p) => (typeof p === 'object' ? p.id : p));
      await menuService.reorderMenu(req.user.id, category_id, ids);
      return successResponse(res, 'Menu reordered successfully');
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to reorder menu', 400);
    }
  }

  async getTableProductList(req, res, next) {
    try {
      const data = await menuService.getTableProductList(req.user.id, req.lang);
      return successResponse(res, 'Table product list fetched', data);
    } catch (err) {
      return errorResponse(res, err.message || 'Failed to fetch table products', 400);
    }
  }
}

module.exports = new MenuController();
