import 'dart:io';
import '../../core/utils/resource.dart';
import '../../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

class UpdateMenuItemUseCase {
  final MenuRepository repository;

  UpdateMenuItemUseCase(this.repository);

  Future<Resource<MenuItemModel>> execute({
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
  }) {
    return repository.updateMenuItem(
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
  }
}
