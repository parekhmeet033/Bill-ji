import 'dart:io';
import 'package:flutter/material.dart';
import '../core/utils/resource.dart';
import '../core/error/failures.dart';
import '../domain/usecases/get_menu_usecase.dart';
import '../domain/usecases/get_category_usecase.dart';
import '../domain/usecases/add_category_usecase.dart';
import '../domain/usecases/update_category_usecase.dart';
import '../domain/usecases/delete_category_usecase.dart';
import '../domain/usecases/reorder_categories_usecase.dart';
import '../domain/usecases/reorder_menu_usecase.dart';
import '../models/category_model.dart';
import '../models/table_product_list_model.dart';
import '../domain/usecases/add_menu_item_usecase.dart';
import '../domain/usecases/update_menu_item_usecase.dart';
import '../domain/usecases/update_menu_status_usecase.dart';
import '../domain/usecases/delete_menu_usecase.dart';
import '../domain/usecases/get_table_product_list_usecase.dart';
import '../models/menu_item_model.dart';

class MenuProvider extends ChangeNotifier {
  final GetMenuUseCase? getMenuUseCase;
  final GetCategoryUseCase? getCategoryUseCase;
  final AddCategoryUseCase? addCategoryUseCase;
  final UpdateCategoryUseCase? updateCategoryUseCase;
  final DeleteCategoryUseCase? deleteCategoryUseCase;
  final ReorderCategoriesUseCase? reorderCategoriesUseCase;
  final ReorderMenuUseCase? reorderMenuUseCase;
  final AddMenuItemUseCase? addMenuItemUseCase;
  final UpdateMenuItemUseCase? updateMenuItemUseCase;
  final UpdateMenuStatusUseCase? updateMenuStatusUseCase;
  final DeleteMenuUseCase? deleteMenuUseCase;
  final GetTableProductListUseCase? getTableProductListUseCase;

  MenuProvider({
    this.getMenuUseCase,
    this.getCategoryUseCase,
    this.addCategoryUseCase,
    this.updateCategoryUseCase,
    this.deleteCategoryUseCase,
    this.reorderCategoriesUseCase,
    this.reorderMenuUseCase,
    this.addMenuItemUseCase,
    this.updateMenuItemUseCase,
    this.updateMenuStatusUseCase,
    this.deleteMenuUseCase,
    this.getTableProductListUseCase,
  });

  List<MenuItemModel> _menuItems = [];
  Resource<List<MenuItemModel>> _menuResource = Initial();

  List<CategoryModel> _categories = [];
  Resource<List<CategoryModel>> _categoryResource = Initial();

  List<TableCategoryModel> _tableCategories = [];
  Resource<List<TableCategoryModel>> _tableCategoryResource = Initial();
  List<TableProductModel> _tableProducts = [];

  Resource<MenuItemModel> _addItemResource = Initial();
  Resource<MenuItemModel> _updateItemResource = Initial();
  Resource<void> _updateStatusResource = Initial();
  Resource<void> _deleteResource = Initial();

  List<MenuItemModel> get menuItems => _menuItems;

  Resource<List<MenuItemModel>> get menuResource => _menuResource;

  List<CategoryModel> get categories => _categories;

  Resource<List<CategoryModel>> get categoryResource => _categoryResource;

  List<TableCategoryModel> get tableCategories => _tableCategories;

  Resource<List<TableCategoryModel>> get tableCategoryResource => _tableCategoryResource;

  List<TableProductModel> get tableProducts => _tableProducts;

  Resource<MenuItemModel> get addItemResource => _addItemResource;

  Resource<MenuItemModel> get updateItemResource => _updateItemResource;

  Resource<void> get updateStatusResource => _updateStatusResource;

  Resource<void> get deleteResource => _deleteResource;

  Future<void> fetchMenu() async {
    if (getMenuUseCase == null) return;

    _menuResource = Loading();
    notifyListeners();

    _menuResource = await getMenuUseCase!.execute();
    if (_menuResource is Success) {
      _menuItems = List<MenuItemModel>.from(_menuResource.data ?? []);
    }
    notifyListeners();
  }

  Future<void> fetchTableProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _tableCategories.isNotEmpty) {
      return;
    }

    debugPrint('MenuProvider: fetchTableProducts called');
    if (getTableProductListUseCase == null) {
      debugPrint('MenuProvider: getTableProductListUseCase is NULL');
      return;
    }

    _tableCategoryResource = Loading();
    notifyListeners();

    debugPrint('MenuProvider: Executing getTableProductListUseCase');
    final result = await getTableProductListUseCase!.execute();
    if (result is Success) {
      _tableCategories = List<TableCategoryModel>.from(result.data ?? []);
      _tableProducts = _tableCategories.expand((cat) => cat.products).toList();
      _tableCategoryResource = Success(_tableCategories);
    } else if (result is Error) {
      _tableCategoryResource = Error(result.failure!);
    }
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    if (getCategoryUseCase == null) return;

    _categoryResource = Loading();
    notifyListeners();

    _categoryResource = await getCategoryUseCase!.execute();
    if (_categoryResource is Success) {
      _categories = List<CategoryModel>.from(_categoryResource.data ?? []);
    }
    notifyListeners();
  }

  Future<Resource<void>> addCategory({required String name, File? image, List<ProductVariantModel> subcategories = const []}) async {
    if (addCategoryUseCase == null) return Error(UnknownFailure('UseCase not initialized'));
    final result = await addCategoryUseCase!.execute(name: name, image: image, subcategories: subcategories);
    if (result is Success) await fetchCategories();
    return result;
  }

  Future<Resource<void>> updateCategory({required int id, required String name, File? image, List<ProductVariantModel> subcategories = const []}) async {
    if (updateCategoryUseCase == null) return Error(UnknownFailure('UseCase not initialized'));
    final result = await updateCategoryUseCase!.execute(id: id, name: name, image: image, subcategories: subcategories);
    if (result is Success) await fetchCategories();
    return result;
  }

  Future<Resource<void>> deleteCategory(int id) async {
    if (deleteCategoryUseCase == null) return Error(UnknownFailure('UseCase not initialized'));
    final result = await deleteCategoryUseCase!.execute(id);
    if (result is Success) {
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    }
    return result;
  }

  Future<Resource<void>> reorderCategories(List<int> ids) async {
    if (reorderCategoriesUseCase == null) return Error(UnknownFailure('UseCase not initialized'));
    return reorderCategoriesUseCase!.execute(ids);
  }

  Future<Resource<void>> reorderMenu({required int categoryId, required List<int> productIds}) async {
    if (reorderMenuUseCase == null) return Error(UnknownFailure('UseCase not initialized'));
    return reorderMenuUseCase!.execute(categoryId: categoryId, productIds: productIds);
  }

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
  }) async {
    if (addMenuItemUseCase == null) {
      return Error(UnknownFailure('UseCase not initialized'));
    }

    _addItemResource = Loading();
    notifyListeners();

    final result = await addMenuItemUseCase!.execute(
      image: image,
      categoryId: categoryId,
      name: name,
      unit: unit,
      price: price,
      description: description,
      halfPrice: halfPrice,
      gstApplicable: gstApplicable,
      gstRate: gstRate,
      variants: variants,
    );

    _addItemResource = result;
    if (result is Success && result.data != null) {
      _menuItems.insert(0, result.data!);
    }
    notifyListeners();
    return result;
  }

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
  }) async {
    if (updateMenuItemUseCase == null) {
      return Error(UnknownFailure('UseCase not initialized'));
    }

    _updateItemResource = Loading();
    notifyListeners();

    final result = await updateMenuItemUseCase!.execute(
      id: id,
      categoryId: categoryId,
      image: image,
      name: name,
      unit: unit,
      price: price,
      description: description,
      halfPrice: halfPrice,
      gstApplicable: gstApplicable,
      gstRate: gstRate,
      variants: variants,
    );

    _updateItemResource = result;
    if (result is Success && result.data != null) {
      final index = _menuItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _menuItems[index] = result.data!;
      }
    }
    notifyListeners();
    return result;
  }

  Future<Resource<void>> deleteMenuItem(String productId) async {
    if (deleteMenuUseCase == null) {
      return Error(UnknownFailure('UseCase not initialized'));
    }

    _deleteResource = Loading();
    notifyListeners();

    final result = await deleteMenuUseCase!.execute(productId);

    _deleteResource = result;
    if (result is Success) {
      _menuItems.removeWhere((item) => item.id == productId);
    }
    notifyListeners();
    return result;
  }

  void addMenuItemLocal(MenuItemModel item) {
    _menuItems.insert(0, item);
    notifyListeners();
  }

  Future<Resource<void>> toggleAvailability(String id) async {
    if (updateMenuStatusUseCase == null) return Error(ServerFailure('UseCase not initialized'));

    final index = _menuItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _menuItems[index];
      final newStatus = !item.isAvailable;

      _menuItems[index] = _updateModelAvailability(item, newStatus);
      notifyListeners();

      _updateStatusResource = Loading();
      final result = await updateMenuStatusUseCase!.execute(productId: id, status: newStatus ? 1 : 0);

      _updateStatusResource = result;
      if (result is Error) {
        _menuItems[index] = _updateModelAvailability(item, !newStatus);
      }
      notifyListeners();
      return result;
    }
    return Error(ServerFailure('Item not found'));
  }

  MenuItemModel _updateModelAvailability(MenuItemModel item, bool isAvailable) {
    return MenuItemModel(
      id: item.id,
      categoryId: item.categoryId,
      categoryName: item.categoryName,
      categoryImage: item.categoryImage,
      name: item.name,
      description: item.description,
      price: item.price,
      halfPrice: item.halfPrice,
      fullPrice: item.fullPrice,
      unit: item.unit,
      rawUnit: item.rawUnit,
      image: item.image,
      isAvailable: isAvailable,
      gstApplicable: item.gstApplicable,
      gstRate: item.gstRate,
      variants: item.variants,
    );
  }
}
