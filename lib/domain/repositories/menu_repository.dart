import 'dart:io';
import '../../core/utils/resource.dart';
import '../../models/menu_item_model.dart';
import '../../models/category_model.dart';
import '../../models/table_product_list_model.dart';

abstract class MenuRepository {
  Future<Resource<List<MenuItemModel>>> getMenuList();
  Future<Resource<List<CategoryModel>>> getCategoryList();
  Future<Resource<void>> deleteMenuItem(String productId);
  Future<Resource<MenuItemModel>> addMenuItem({
    required File image,
    required int categoryId,
    required String name,
    required String unit,
    required String price,
    String? description,
    String? halfPrice,
    bool gstApplicable = false,
    double gstRate = 0.0,
    List<ProductVariantModel> variants = const [],
  });
  Future<Resource<MenuItemModel>> updateMenuItem({
    required String id,
    required int categoryId,
    File? image,
    required String name,
    required String unit,
    required String price,
    String? description,
    String? halfPrice,
    bool gstApplicable = false,
    double gstRate = 0.0,
    List<ProductVariantModel> variants = const [],
  });
  Future<Resource<void>> updateMenuStatus({
    required String productId,
    required int status,
  });
  Future<Resource<void>> addCategory({required String name, File? image, List<ProductVariantModel> subcategories = const []});
  Future<Resource<void>> updateCategory({required int id, required String name, File? image, List<ProductVariantModel> subcategories = const []});
  Future<Resource<void>> deleteCategory(int id);
  Future<Resource<void>> reorderCategories(List<int> ids);
  Future<Resource<void>> reorderMenu({required int categoryId, required List<int> productIds});
  Future<Resource<List<TableCategoryModel>>> getTableProductList();
}
