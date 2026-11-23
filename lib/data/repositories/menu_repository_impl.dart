import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:lineless/core/error/error_handler.dart';
import 'package:lineless/core/network/network_info.dart';
import 'package:lineless/core/error/failures.dart';
import 'package:lineless/core/utils/resource.dart';
import 'package:lineless/models/menu_item_model.dart';
import 'package:lineless/models/category_model.dart';
import 'package:lineless/models/table_product_list_model.dart';
import 'package:lineless/domain/repositories/menu_repository.dart';
import 'package:lineless/data/datasources/menu_remote_data_source.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MenuRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Resource<List<CategoryModel>>> getCategoryList() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getCategoryList();
        return Success(categories);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<List<MenuItemModel>>> getMenuList() async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getMenuList();
        return Success(products);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> deleteMenuItem(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteMenuItem(productId);
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<MenuItemModel>> addMenuItem({
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
    if (await networkInfo.isConnected) {
      try {
        final product = await remoteDataSource.addMenuItem(
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
        return Success(product);
      } catch (e, stack) {
        debugPrintStack(stackTrace: stack);
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<MenuItemModel>> updateMenuItem({
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
    if (await networkInfo.isConnected) {
      try {
        final product = await remoteDataSource.updateMenuItem(
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
        return Success(product);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> updateMenuStatus({
    required String productId,
    required int status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateMenuStatus(
          productId: productId,
          status: status,
        );
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> addCategory({required String name, File? image, List<ProductVariantModel> subcategories = const []}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addCategory(name: name, image: image, subcategories: subcategories);
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> updateCategory({required int id, required String name, File? image, List<ProductVariantModel> subcategories = const []}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateCategory(id: id, name: name, image: image, subcategories: subcategories);
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> deleteCategory(int id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCategory(id);
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> reorderCategories(List<int> ids) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.reorderCategories(ids);
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> reorderMenu({required int categoryId, required List<int> productIds}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.reorderMenu(categoryId: categoryId, productIds: productIds);
        return Success(null);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<List<TableCategoryModel>>> getTableProductList() async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getTableProductList();
        return Success(products);
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }
}
