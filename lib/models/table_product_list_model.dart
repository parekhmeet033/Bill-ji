import 'menu_item_model.dart';

class TableCategoryModel {
  final int id;
  final String name;
  final String? image;
  final List<ProductVariantModel> subcategories;
  final List<TableProductModel> products;

  TableCategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.subcategories = const [],
    required this.products,
  });

  factory TableCategoryModel.fromJson(Map<String, dynamic> json) {
    final String catName = json['name'] ?? '';
    List<ProductVariantModel> parsedSubcategories = [];
    if (json['subcategories'] != null && json['subcategories'] is List) {
      parsedSubcategories = (json['subcategories'] as List)
          .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return TableCategoryModel(
      id: json['id'] ?? 0,
      name: catName,
      image: json['image'],
      subcategories: parsedSubcategories,
      products: (json['products'] as List? ?? [])
          .map((p) => TableProductModel.fromJson(p, categoryName: catName, categorySubcategories: parsedSubcategories))
          .toList(),
    );
  }
}

class TableProductModel {
  final int id;
  final int categoryId;
  final String? categoryName;
  final String name;
  final String? description;
  final String? unit;
  final String price;
  final String? halfPrice;
  final String? image;
  final bool gstApplicable;
  final double gstRate;
  final List<ProductVariantModel> variants;
  final List<ProductVariantModel> subcategories;

  TableProductModel({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.name,
    this.description,
    this.unit,
    required this.price,
    this.halfPrice,
    this.image,
    this.gstApplicable = false,
    this.gstRate = 0.0,
    this.variants = const [],
    this.subcategories = const [],
  });

  bool get isNewDish =>
      (categoryName != null && categoryName!.trim().toLowerCase() == 'new dish') ||
      name.trim().toLowerCase() == 'new dish';

  bool isNewDishCategory(List<TableCategoryModel> categories) {
    if (isNewDish) return true;
    for (final c in categories) {
      if (c.id == categoryId && c.name.trim().toLowerCase() == 'new dish') {
        return true;
      }
    }
    return false;
  }

  bool get isCustomizable => variants.isNotEmpty || subcategories.isNotEmpty || isNewDish;
  List<ProductVariantModel> get options => variants.isNotEmpty ? variants : subcategories;

  factory TableProductModel.fromJson(
    Map<String, dynamic> json, {
    String? categoryName,
    List<ProductVariantModel>? categorySubcategories,
  }) {
    List<ProductVariantModel> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<ProductVariantModel> parsedSubcategories = categorySubcategories ?? [];
    if (json['subcategories'] != null && json['subcategories'] is List) {
      parsedSubcategories = (json['subcategories'] as List)
          .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return TableProductModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      categoryName: categoryName ?? json['category_name'],
      name: json['name'] ?? '',
      description: json['description'],
      unit: json['unit'],
      price: json['price']?.toString() ?? '0',
      halfPrice: json['half_price']?.toString(),
      image: json['image'],
      gstApplicable: json['gst_applicable'] == 1 || json['gst_applicable'] == '1' || json['gst_applicable'] == true,
      gstRate: double.tryParse(json['gst_rate']?.toString() ?? '0') ?? 0.0,
      variants: parsedVariants,
      subcategories: parsedSubcategories,
    );
  }

  double calculateTotal(double qty, {double optionsPrice = 0.0}) {
    final double baseP = double.tryParse(price) ?? 0;
    final double p = baseP + optionsPrice;
    final double hp = double.tryParse(halfPrice ?? '') ?? 0;

    if (qty <= 0) return 0;

    if (unit?.toUpperCase() == 'KG') {
      return qty * p;
    }

    int fullQty = qty.floor();
    double remainder = double.parse((qty - fullQty).toStringAsFixed(1));

    double total = fullQty * p;
    if (remainder == 0.5 && hp > 0) {
      total += (hp + optionsPrice);
    } else {
      total += remainder * p;
    }
    return total;
  }
}
