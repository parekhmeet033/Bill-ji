import '../../models/menu_item_model.dart';

class MenuItemApiModel extends MenuItemModel {
  MenuItemApiModel({
    required super.id,
    super.categoryId,
    super.categoryName,
    super.categoryImage,
    required super.name,
    super.description,
    super.price,
    super.halfPrice,
    super.fullPrice,
    required super.unit,
    super.rawUnit,
    super.isAvailable,
    super.image,
    super.gstApplicable,
    super.gstRate,
    super.variants,
  });

  factory MenuItemApiModel.fromJson(Map<String, dynamic> json) {
    final rawUnit = json['unit']?.toString();
    final unit = _mapUnit(rawUnit);
    final price = double.tryParse(json['price']?.toString() ?? '0');

    List<ProductVariantModel> parsedVariants = [];
    if (json['variants'] != null && json['variants'] is List) {
      parsedVariants = (json['variants'] as List)
          .map((e) => ProductVariantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return MenuItemApiModel(
      id: json['id'].toString(),
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name'],
      categoryImage: json['category_image'],
      name: json['name'] ?? '',
      description: json['description'],
      unit: unit,
      rawUnit: rawUnit,
      price: price,
      fullPrice: unit == PriceUnit.plate ? price : null,
      halfPrice: json['half_price'] != null ? double.tryParse(json['half_price'].toString()) : null,
      image: json['image'],
      isAvailable: json['status'] == 1,
      gstApplicable: json['gst_applicable'] == 1 || json['gst_applicable'] == '1' || json['gst_applicable'] == true,
      gstRate: double.tryParse(json['gst_rate']?.toString() ?? '0') ?? 0.0,
      variants: parsedVariants,
    );
  }

  static PriceUnit _mapUnit(String? unit) {
    switch (unit?.toUpperCase()) {
      case 'KG':
        return PriceUnit.weight;
      case 'QTY':
      case 'NOS':
        return PriceUnit.quantity;
      case 'PLATE':
        return PriceUnit.plate;
      case 'VARIANT':
        return PriceUnit.plate;
      default:
        return PriceUnit.quantity;
    }
  }
}
