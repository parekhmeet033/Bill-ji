import 'dart:convert';
import 'menu_item_model.dart';

class CategoryModel {
  final int id;
  final int userId;
  final String name;
  final String? image;
  final int status;
  final int sortOrder;
  final int productsCount;
  final List<MenuItemModel> products;
  final List<ProductVariantModel> subcategories;

  CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.image,
    required this.status,
    required this.sortOrder,
    required this.productsCount,
    this.products = const [],
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, {List<MenuItemModel> Function(List)? productsMapper}) {
    List<ProductVariantModel> parsedSubcategories = [];
    if (json['subcategories'] != null) {
      if (json['subcategories'] is List) {
        parsedSubcategories = (json['subcategories'] as List)
            .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (json['subcategories'] is String && json['subcategories'].toString().trim().isNotEmpty) {
        try {
          final List list = jsonDecode(json['subcategories']);
          parsedSubcategories = list
              .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } catch (_) {}
      }
    }

    return CategoryModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'],
      status: json['status'] ?? 0,
      sortOrder: json['sort_order'] ?? 0,
      productsCount: json['products_count'] ?? 0,
      products: productsMapper != null && json['products'] != null 
          ? productsMapper(json['products'] as List) 
          : [],
      subcategories: parsedSubcategories,
    );
  }
}
