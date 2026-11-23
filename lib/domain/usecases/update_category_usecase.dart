import 'dart:io';
import '../../core/utils/resource.dart';
import '../../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

class UpdateCategoryUseCase {
  final MenuRepository repository;

  UpdateCategoryUseCase(this.repository);

  Future<Resource<void>> execute({required int id, required String name, File? image, List<ProductVariantModel> subcategories = const []}) {
    return repository.updateCategory(id: id, name: name, image: image, subcategories: subcategories);
  }
}
