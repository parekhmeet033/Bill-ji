import 'dart:io';
import '../../core/utils/resource.dart';
import '../../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

class AddCategoryUseCase {
  final MenuRepository repository;

  AddCategoryUseCase(this.repository);

  Future<Resource<void>> execute({required String name, File? image, List<ProductVariantModel> subcategories = const []}) {
    return repository.addCategory(name: name, image: image, subcategories: subcategories);
  }
}
