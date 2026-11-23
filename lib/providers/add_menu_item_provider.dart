import 'dart:io';
import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';

class AddMenuItemProvider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController halfPriceController = TextEditingController();
  final TextEditingController fullPriceController = TextEditingController();

  PriceUnit _selectedUnit = PriceUnit.quantity;
  int? _selectedCategoryId;
  File? _selectedImage;
  bool _isGstApplicable = false;
  double _selectedGstRate = 5.0;
  List<ProductVariantModel> _variants = [];

  PriceUnit get selectedUnit => _selectedUnit;
  int? get selectedCategoryId => _selectedCategoryId;
  File? get selectedImage => _selectedImage;
  bool get isGstApplicable => _isGstApplicable;
  double get selectedGstRate => _selectedGstRate;
  List<ProductVariantModel> get variants => _variants;

  void init(MenuItemModel? item) {
    _selectedUnit = item?.unit ?? PriceUnit.quantity;
    _selectedCategoryId = item?.categoryId;
    _selectedImage = null;
    _isGstApplicable = item?.gstApplicable ?? false;
    _selectedGstRate = item?.gstRate != null && item!.gstRate > 0 ? item.gstRate : 5.0;
    _variants = List<ProductVariantModel>.from(item?.variants ?? []);

    nameController.text = item?.name ?? '';
    descController.text = item?.description ?? '';
    priceController.text = item?.price?.toStringAsFixed(0) ?? '';
    halfPriceController.text = item?.halfPrice?.toStringAsFixed(0) ?? '';
    fullPriceController.text = item?.fullPrice?.toStringAsFixed(0) ?? '';
    
    notifyListeners();
  }

  void setUnit(PriceUnit unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void setCategoryId(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  void setGstApplicable(bool value) {
    _isGstApplicable = value;
    if (value && _selectedGstRate <= 0) {
      _selectedGstRate = 5.0;
    }
    notifyListeners();
  }

  void setGstRate(double rate) {
    _selectedGstRate = rate;
    notifyListeners();
  }

  void addVariant(String name, double price) {
    _variants.add(ProductVariantModel(name: name, price: price));
    notifyListeners();
  }

  void removeVariant(int index) {
    if (index >= 0 && index < _variants.length) {
      _variants.removeAt(index);
      notifyListeners();
    }
  }

  void reset() {
    _selectedUnit = PriceUnit.quantity;
    _selectedCategoryId = null;
    _selectedImage = null;
    _isGstApplicable = false;
    _selectedGstRate = 5.0;
    _variants = [];
    nameController.clear();
    descController.clear();
    priceController.clear();
    halfPriceController.clear();
    fullPriceController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    priceController.dispose();
    halfPriceController.dispose();
    fullPriceController.dispose();
    super.dispose();
  }
}
