import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/menu_item_api_model.dart';
import '../../models/category_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/table_product_list_model.dart';

abstract class MenuRemoteDataSource {
  Future<List<MenuItemApiModel>> getMenuList();
  Future<List<CategoryModel>> getCategoryList();
  Future<void> deleteMenuItem(String productId);
  Future<MenuItemApiModel> addMenuItem({
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
  });
  Future<MenuItemApiModel> updateMenuItem({
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
  });
  Future<void> updateMenuStatus({
    required String productId,
    required int status,
  });
  Future<void> addCategory({required String name, File? image, List<ProductVariantModel> subcategories = const []});
  Future<void> updateCategory({required int id, required String name, File? image, List<ProductVariantModel> subcategories = const []});
  Future<void> deleteCategory(int id);
  Future<void> reorderCategories(List<int> ids);
  Future<void> reorderMenu({required int categoryId, required List<int> productIds});
  Future<List<TableCategoryModel>> getTableProductList();
}

class MenuRemoteDataSourceImpl implements MenuRemoteDataSource {
  final DioClient dioClient;

  MenuRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<CategoryModel>> getCategoryList() async {
    final response = await dioClient.post(ApiConstants.categoryList);

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] == true) {
      final List data = response.data['data'] ?? [];
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch categories');
    }
  }

  @override
  Future<List<MenuItemApiModel>> getMenuList() async {
    final response = await dioClient.post(ApiConstants.menuList);
    
    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] == true) {
      final List products = response.data['product'] ?? [];
      return products.map((e) => MenuItemApiModel.fromJson(e)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch menu');
    }
  }

  @override
  Future<void> deleteMenuItem(String productId) async {
    final response = await dioClient.post(
      ApiConstants.menuDestroy,
      data: {'product_id': productId},
    );

    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete product');
    }
  }

  @override
  Future<MenuItemApiModel> addMenuItem({
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
  }) async {
    final String fileName = image.path.split('/').last;
    final String extension = fileName.split('.').last.toLowerCase();

    MediaType? contentType;
    if (extension == 'jpg' || extension == 'jpeg') {
      contentType = MediaType('image', 'jpeg');
    } else if (extension == 'png') {
      contentType = MediaType('image', 'png');
    }

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: fileName,
        contentType: contentType,
      ),
      'category_id': categoryId,
      'name': name,
      'unit': unit,
      'price': price,
      if (description != null) 'description': description,
      if (halfPrice != null) 'half_price': halfPrice,
      'gst_applicable': gstApplicable ? '1' : '0',
      'gst_rate': gstRate.toString(),
      'variants': jsonEncode(variants.map((v) => v.toJson()).toList()),
    });

    final response = await dioClient.post(
      ApiConstants.menuAdd,
      data: formData,
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] == true) {
      return MenuItemApiModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to add product');
    }
  }

  @override
  Future<MenuItemApiModel> updateMenuItem({
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
  }) async {
    final Map<String, dynamic> data = {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'unit': unit,
      'price': price,
      if (description != null) 'description': description,
      if (halfPrice != null) 'half_price': halfPrice,
      'gst_applicable': gstApplicable ? '1' : '0',
      'gst_rate': gstRate.toString(),
      'variants': jsonEncode(variants.map((v) => v.toJson()).toList()),
    };

    if (image != null) {
      final String fileName = image.path.split('/').last;
      final String extension = fileName.split('.').last.toLowerCase();
      MediaType? contentType;
      if (extension == 'jpg' || extension == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        contentType = MediaType('image', 'png');
      }

      data['image'] = await MultipartFile.fromFile(
        image.path,
        filename: fileName,
        contentType: contentType,
      );
    }

    final formData = FormData.fromMap(data);

    final response = await dioClient.post(
      ApiConstants.menuUpdate,
      data: formData,
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] == true) {
      return MenuItemApiModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to update product');
    }
  }

  @override
  Future<void> updateMenuStatus({
    required String productId,
    required int status,
  }) async {
    final response = await dioClient.post(
      ApiConstants.menuStatus,
      data: {
        'product_id': productId,
        'status': status,
      },
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['success'] != true && response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to update status');
    }
  }

  @override
  Future<void> addCategory({required String name, File? image, List<ProductVariantModel> subcategories = const []}) async {
    final Map<String, dynamic> data = {
      'name': name,
      'subcategories': jsonEncode(subcategories.map((s) => s.toJson()).toList()),
    };
    if (image != null) {
      data['image'] = await _multipartFromFile(image);
    }
    final response = await dioClient.post(
      ApiConstants.categoryAdd,
      data: FormData.fromMap(data),
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to add category');
    }
  }

  @override
  Future<void> updateCategory({required int id, required String name, File? image, List<ProductVariantModel> subcategories = const []}) async {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'subcategories': jsonEncode(subcategories.map((s) => s.toJson()).toList()),
    };
    if (image != null) {
      data['image'] = await _multipartFromFile(image);
    }
    final response = await dioClient.post(
      ApiConstants.categoryUpdate,
      data: FormData.fromMap(data),
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to update category');
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    final response = await dioClient.post(
      ApiConstants.categoryDestroy,
      data: {'id': id},
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to delete category');
    }
  }

  @override
  Future<void> reorderCategories(List<int> ids) async {
    final response = await dioClient.post(
      ApiConstants.categoryReorder,
      data: {
        'categories': ids.map((id) => {'id': id}).toList(),
      },
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to reorder categories');
    }
  }

  @override
  Future<void> reorderMenu({required int categoryId, required List<int> productIds}) async {
    final response = await dioClient.post(
      ApiConstants.menuReorder,
      data: {
        'category_id': categoryId,
        'product_ids': productIds.map((id) => {'id': id}).toList(),
      },
    );

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] != true) {
      throw Exception(response.data['message'] ?? 'Failed to reorder menu');
    }
  }

  @override
  Future<List<TableCategoryModel>> getTableProductList() async {
    final response = await dioClient.post(ApiConstants.tableProductList);

    if (response.data is! Map) {
      throw Exception('Server returned an invalid response. Please try again.');
    }

    if (response.data['status'] == true) {
      final List data = response.data['data'] ?? [];
      return data.map((e) => TableCategoryModel.fromJson(e)).toList();
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch table products');
    }
  }

  Future<MultipartFile> _multipartFromFile(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    MediaType? contentType;
    if (ext == 'jpg' || ext == 'jpeg') {
      contentType = MediaType('image', 'jpeg');
    } else if (ext == 'png') {
      contentType = MediaType('image', 'png');
    }
    return MultipartFile.fromFile(file.path, filename: fileName, contentType: contentType);
  }
}
