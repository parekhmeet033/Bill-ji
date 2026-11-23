import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../core/utils/resource.dart';
import '../core/error/failures.dart';
import 'menu_provider.dart';

class MenuManagementProvider extends ChangeNotifier {
  String _selectedFilter = "All";
  int? _selectedCategoryId;
  List<CategoryModel> _localCategories = [];
  bool _hasReordered = false;
  bool _isSavingOrder = false;
  List<MenuItemModel> _localMenuItems = [];
  bool _hasMenuReordered = false;
  bool _isSavingMenuOrder = false;

  // Getters
  String get selectedFilter => _selectedFilter;
  int? get selectedCategoryId => _selectedCategoryId;
  List<CategoryModel> get localCategories => _localCategories;
  bool get hasReordered => _hasReordered;
  bool get isSavingOrder => _isSavingOrder;
  List<MenuItemModel> get localMenuItems => _localMenuItems;
  bool get hasMenuReordered => _hasMenuReordered;
  bool get isSavingMenuOrder => _isSavingMenuOrder;

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void syncLocalCategories(List<CategoryModel> categories) {
    _localCategories = List.from(categories);
    _hasReordered = false;
    notifyListeners();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _localCategories.removeAt(oldIndex);
    _localCategories.insert(newIndex, item);
    _hasReordered = true;
    notifyListeners();
  }

  void selectCategory(int? categoryId, List<MenuItemModel> allItems) {
    _selectedCategoryId = categoryId;
    if (categoryId == null) {
      _localMenuItems = [];
    } else {
      _localMenuItems = allItems.where((item) => item.categoryId == categoryId).toList();
    }
    _hasMenuReordered = false;
    notifyListeners();
  }

  void reorderMenuItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _localMenuItems.removeAt(oldIndex);
    _localMenuItems.insert(newIndex, item);
    _hasMenuReordered = true;
    notifyListeners();
  }

  Future<Resource<void>> saveCategoryOrder(MenuProvider menuProvider) async {
    _isSavingOrder = true;
    notifyListeners();
    
    final ids = _localCategories.map((c) => c.id).toList();
    final result = await menuProvider.reorderCategories(ids);
    
    _isSavingOrder = false;
    if (result is Success) {
      _hasReordered = false;
    }
    notifyListeners();
    return result;
  }

  Future<Resource<void>> saveMenuOrder(MenuProvider menuProvider) async {
    if (_selectedCategoryId == null) return Error(ValidationFailure('No category selected'));
    
    _isSavingMenuOrder = true;
    notifyListeners();
    
    final productIds = _localMenuItems.map((item) => int.tryParse(item.id) ?? 0).where((id) => id != 0).toList();
    final result = await menuProvider.reorderMenu(categoryId: _selectedCategoryId!, productIds: productIds);
    
    _isSavingMenuOrder = false;
    if (result is Success) {
      _hasMenuReordered = false;
    }
    notifyListeners();
    return result;
  }

  void updateLocalMenuItem(MenuItemModel updatedItem) {
    final index = _localMenuItems.indexWhere((m) => m.id == updatedItem.id);
    if (index != -1) {
      _localMenuItems[index] = updatedItem;
      notifyListeners();
    }
  }

  void removeLocalMenuItem(String id) {
    _localMenuItems.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
