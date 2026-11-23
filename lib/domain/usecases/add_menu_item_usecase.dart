import 'dart:io';
import '../../core/utils/resource.dart';
import '../../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

class AddMenuItemUseCase {
  final MenuRepository repository;

  AddMenuItemUseCase(this.repository);

  Future<Resource<MenuItemModel>> execute({
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
  }) {
    return repository.addMenuItem(
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
  }
}
