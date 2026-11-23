const menuRepository = require('../repositories/menuRepository');

class MenuService {
  async getCategoryList(userId, lang = 'en') {
    return await menuRepository.getCategories(userId, lang);
  }

  async addCategory(userId, name, file, subcategories) {
    const image = file ? file.filename : null;
    return await menuRepository.addCategory(userId, name, image, subcategories);
  }

  async updateCategory(userId, id, name, file, subcategories) {
    const image = file ? file.filename : null;
    return await menuRepository.updateCategory(userId, id, name, image, subcategories);
  }

  async deleteCategory(userId, id) {
    return await menuRepository.deleteCategory(userId, id);
  }

  async reorderCategories(userId, categoryIds) {
    return await menuRepository.reorderCategories(userId, categoryIds);
  }

  async getMenuList(userId, lang = 'en') {
    return await menuRepository.getProducts(userId, lang);
  }

  async addMenuItem(userId, productData, file) {
    if (file) {
      productData.image = file.filename;
    }
    return await menuRepository.addProduct(userId, productData);
  }

  async updateMenuItem(userId, productId, productData, file) {
    if (file) {
      productData.image = file.filename;
    }
    return await menuRepository.updateProduct(userId, productId, productData);
  }

  async updateMenuStatus(userId, productId, status) {
    return await menuRepository.updateProductStatus(userId, productId, status);
  }

  async deleteMenuItem(userId, productId) {
    return await menuRepository.deleteProduct(userId, productId);
  }

  async reorderMenu(userId, categoryId, productIds) {
    return await menuRepository.reorderMenu(userId, categoryId, productIds);
  }

  async getTableProductList(userId, lang = 'en') {
    return await menuRepository.getTableProducts(userId, lang);
  }
}

module.exports = new MenuService();
