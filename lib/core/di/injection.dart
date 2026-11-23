import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../network/reverb_service.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/datasources/menu_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import '../../domain/usecases/get_orders_list_usecase.dart';
import '../../domain/usecases/get_pending_tables_usecase.dart';
import '../../domain/usecases/get_reports_analytics_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';
import '../../domain/usecases/delete_orders_usecase.dart';
import '../../domain/usecases/forgot_pin_usecase.dart';
import '../../domain/usecases/get_menu_usecase.dart';
import '../../domain/usecases/get_category_usecase.dart';
import '../../domain/usecases/add_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/reorder_categories_usecase.dart';
import '../../domain/usecases/reorder_menu_usecase.dart';
import '../../domain/usecases/delete_menu_usecase.dart';
import '../../domain/usecases/add_menu_item_usecase.dart';
import '../../domain/usecases/update_menu_item_usecase.dart';
import '../../domain/usecases/update_menu_status_usecase.dart';
import '../../domain/usecases/get_table_product_list_usecase.dart';
import '../../domain/usecases/save_table_order_usecase.dart';
import '../../domain/usecases/create_pos_order_usecase.dart';
import '../../domain/usecases/get_pos_draft_usecase.dart';
import '../../domain/usecases/save_pos_draft_usecase.dart';
import '../../domain/usecases/clear_pos_draft_usecase.dart';
import '../../domain/usecases/get_shop_settings_usecase.dart';
import '../../domain/usecases/update_shop_settings_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Hive
  await Hive.initFlutter();
  final tokenBox = await Hive.openBox(CacheConstants.tokenBox);
  sl.registerLazySingleton(() => tokenBox);

  // Network
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => DioClient());
  sl.registerLazySingleton(() => ReverbService());

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<OrderRemoteDataSource>(() => OrderRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<MenuRemoteDataSource>(() => MenuRemoteDataSourceImpl(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
      ));
  sl.registerLazySingleton<MenuRepository>(() => MenuRepositoryImpl(
        remoteDataSource: sl(),
        networkInfo: sl(),
      ));

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetOrdersUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardUseCase(sl()));
  sl.registerLazySingleton(() => GetOrdersListUseCase(sl()));
  sl.registerLazySingleton(() => GetPendingTablesUseCase(sl()));
  sl.registerLazySingleton(() => GetReportsAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOrderStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeleteOrdersUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPinUseCase(sl()));
  sl.registerLazySingleton(() => GetMenuUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryUseCase(sl()));
  sl.registerLazySingleton(() => AddCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCategoryUseCase(sl()));
  sl.registerLazySingleton(() => ReorderCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => ReorderMenuUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMenuUseCase(sl()));
  sl.registerLazySingleton(() => AddMenuItemUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMenuItemUseCase(sl()));
  sl.registerLazySingleton(() => UpdateMenuStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetTableProductListUseCase(sl()));
  sl.registerLazySingleton(() => SaveTableOrderUseCase(sl()));
  sl.registerLazySingleton(() => CreatePosOrderUseCase(sl()));
  sl.registerLazySingleton(() => GetPosDraftUseCase(sl()));
  sl.registerLazySingleton(() => SavePosDraftUseCase(sl()));
  sl.registerLazySingleton(() => ClearPosDraftUseCase(sl()));
  sl.registerLazySingleton(() => GetShopSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopSettingsUseCase(sl()));
}
