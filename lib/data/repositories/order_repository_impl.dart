import '../../core/error/error_handler.dart';
import '../../core/network/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/resource.dart';
import '../../models/dashboard_model.dart';
import '../../models/order_model.dart';
import '../../models/pagination_model.dart';
import '../../models/report_model.dart';
import '../../models/pending_table_model.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  OrderRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Resource<List<OrderModel>>> getOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getOrders();
        if (response.status && response.data != null) {
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to load orders' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<DashboardData>> getDashboardData() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getDashboardData();
        if (response.status && response.data != null) {
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to load dashboard' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<PaginatedData<List<OrderModel>>>> getOrdersList({
    required String status,
    required String orderType,
    required String search,
    required String startDate,
    required String endDate,
    required int page,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getOrdersList(
          status: status,
          orderType: orderType,
          search: search,
          startDate: startDate,
          endDate: endDate,
          page: page,
        );
        if (response.status && response.data != null) {
          return Success(PaginatedData(data: response.data!, pagination: response.pagination));
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to load orders list' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<ReportData>> getReportsAnalytics({String? userPin, String? startDate, String? endDate}) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getReportsAnalytics(userPin: userPin, startDate: startDate, endDate: endDate);
        if (response.status && response.data != null) {
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to load reports' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<String>> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateOrderStatus(
          orderId: orderId,
          status: status,
          paymentType: paymentType,
          upiAmount: upiAmount,
          cashAmount: cashAmount,
        );
        if (response.status) {
          return Success(response.data ?? response.message);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to update status' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> deleteOrders({required String startDate, required String endDate}) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.deleteOrders(startDate: startDate, endDate: endDate);
        if (response.status) {
          return Success(null);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to delete orders' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> forgotPin({required String oldPin, required String newPin}) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.forgotPin(oldPin: oldPin, newPin: newPin);
        if (response.status) {
          return Success(null);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to change PIN' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> saveTableOrder(Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.saveTableOrder(data);
        if (response.status) {
          return Success(null);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to save order' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> createPosOrder(Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.createPosOrder(data);
        if (response.status) {
          return Success(response.data ?? <String, dynamic>{});
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to place order' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> savePosDraft(Map<String, dynamic> data) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.savePosDraft(data);
        if (response.status) {
          return Success(null);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to save draft' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<OrderModel?>> getPosDraft() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getPosDraft();
        if (response.status) {
          return Success(response.data);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to fetch draft' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<void>> clearPosDraft() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.clearPosDraft();
        if (response.status) {
          return Success(null);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to clear draft' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Resource<List<PendingTableModel>>> getPendingTables() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getPendingTables();
        if (response.status && response.data != null) {
          return Success(response.data!);
        } else {
          return Error(ServerFailure(response.message.isEmpty ? 'Failed to load pending tables' : response.message));
        }
      } catch (e) {
        return Error(ErrorHandler.handle(e));
      }
    } else {
      return Error(NetworkFailure('No internet connection'));
    }
  }
}
