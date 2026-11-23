enum PriceUnit { quantity, weight, plate }

class ProductVariantModel {
  final String name;
  final double price;

  ProductVariantModel({
    required this.name,
    required this.price,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}

class MenuItemModel {
  final String id;
  final int? categoryId;
  final String? categoryName;
  final String? categoryImage;
  final String name;
  final String? description;
  final String? image;
  final double? price;
  final double? halfPrice;
  final double? fullPrice;
  final PriceUnit unit;
  final String? rawUnit;
  final bool isAvailable;
  final bool gstApplicable;
  final double gstRate;
  final List<ProductVariantModel> variants;

  MenuItemModel({
    required this.id,
    this.categoryId,
    this.categoryName,
    this.categoryImage,
    required this.name,
    this.description,
    this.price,
    this.halfPrice,
    this.fullPrice,
    required this.unit,
    this.rawUnit,
    this.isAvailable = true,
    this.image,
    this.gstApplicable = false,
    this.gstRate = 0.0,
    this.variants = const [],
  });
}
