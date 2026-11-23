const express = require('express');
const menuController = require('../controllers/menuController');
const authMiddleware = require('../middleware/authMiddleware');
const { uploadProductImage, uploadCategoryImage } = require('../middleware/uploadMiddleware');

const router = express.Router();

// Categories
router.post('/category-list', authMiddleware, (req, res, next) => menuController.getCategoryList(req, res, next));
router.post('/category-add', authMiddleware, uploadCategoryImage.single('image'), (req, res, next) => menuController.addCategory(req, res, next));
router.post('/category-update', authMiddleware, uploadCategoryImage.single('image'), (req, res, next) => menuController.updateCategory(req, res, next));
router.post('/category-destroy', authMiddleware, (req, res, next) => menuController.deleteCategory(req, res, next));
router.post('/category-reorder', authMiddleware, (req, res, next) => menuController.reorderCategories(req, res, next));

// Menu Items
router.post('/menu-list', authMiddleware, (req, res, next) => menuController.getMenuList(req, res, next));
router.post('/menu-add', authMiddleware, uploadProductImage.single('image'), (req, res, next) => menuController.addMenuItem(req, res, next));
router.post('/menu-update', authMiddleware, uploadProductImage.single('image'), (req, res, next) => menuController.updateMenuItem(req, res, next));
router.post('/menu-destroy', authMiddleware, (req, res, next) => menuController.deleteMenuItem(req, res, next));
router.post('/menu-status', authMiddleware, (req, res, next) => menuController.updateMenuStatus(req, res, next));
router.post('/menu-reorder', authMiddleware, (req, res, next) => menuController.reorderMenu(req, res, next));
router.post('/table-product-list', authMiddleware, (req, res, next) => menuController.getTableProductList(req, res, next));

module.exports = router;
