import 'package:easy_localization/easy_localization.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/api_response.dart';
import '../models/order_api_model.dart';
import '../models/dashboard_api_model.dart';
import '../../models/report_model.dart';
import '../../models/pending_table_model.dart';

abstract class OrderRemoteDataSource {
  Future<ApiResponse<List<OrderApiModel>>> getOrders();

  Future<ApiResponse<DashboardApiModel>> getDashboardData();

  Future<ApiResponse<List<OrderApiModel>>> getOrdersList({
    required String status,
    required String orderType,
    required String search,
    required String startDate,
    required String endDate,
    required int page,
  });

  Future<ApiResponse<ReportData>> getReportsAnalytics({String? userPin, String? startDate, String? endDate});

  Future<ApiResponse<String>> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
  });

  Future<ApiResponse<void>> deleteOrders({required String startDate, required String endDate});

  Future<ApiResponse<void>> forgotPin({required String oldPin, required String newPin});

  Future<ApiResponse<void>> saveTableOrder(Map<String, dynamic> data);

  Future<ApiResponse<Map<String, dynamic>>> createPosOrder(Map<String, dynamic> data);

  Future<ApiResponse<void>> savePosDraft(Map<String, dynamic> data);

  Future<ApiResponse<OrderApiModel?>> getPosDraft();

  Future<ApiResponse<void>> clearPosDraft();

  Future<ApiResponse<List<PendingTableModel>>> getPendingTables();
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final DioClient dioClient;

  OrderRemoteDataSourceImpl(this.dioClient);

  @override
  Future<ApiResponse<List<OrderApiModel>>> getOrders() async {
    final response = await dioClient.get('orders'); // Sample endpoint

    return ApiResponse.fromJson(
      response.data,
      (json) => (json as List).map((e) => OrderApiModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<ApiResponse<DashboardApiModel>> getDashboardData() async {
    final response = await dioClient.post(ApiConstants.dashboard);
    return ApiResponse.fromJson(response.data, (json) => DashboardApiModel.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<ApiResponse<List<OrderApiModel>>> getOrdersList({
    required String status,
    required String orderType,
    required String search,
    required String startDate,
    required String endDate,
    required int page,
  }) async {
    final response = await dioClient.post(
      ApiConstants.ordersList,
      data: {
        "status": status,
        "order_type": orderType,
        "search": search,
        "start_date": startDate,
        "end_date": endDate,
        "page": page
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => (json as List).map((e) => OrderApiModel.fromDashboardJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  Future<ApiResponse<ReportData>> getReportsAnalytics({String? userPin, String? startDate, String? endDate}) async {
    final Map<String, dynamic> body = {};
    if (userPin != null) body['user_pin'] = userPin;
    if (startDate != null && startDate.isNotEmpty) body['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) body['end_date'] = endDate;
    final response = await dioClient.post(
      ApiConstants.reportsAnalytics,
      data: body.isEmpty ? null : body,
    );

    if (response.data is! Map) {
      return ApiResponse(status: false, message: 'common.unexpected_response'.tr());
    }

    return ApiResponse.fromJson(response.data, (json) => ReportData.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<ApiResponse<String>> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
  }) async {
    final response = await dioClient.post(
      ApiConstants.ordersStatus,
      data: {
        "status": status,
        "order_id": orderId,
        "payment_type": paymentType,
        "upi_amount": upiAmount,
        "cash_amount": cashAmount,
      },
    );

    final Map<String, dynamic> body = response.data as Map<String, dynamic>;
    final bool success = body['success'] is bool
        ? body['success'] as bool
        : (body['status'] is bool ? body['status'] as bool : false);
    return ApiResponse<String>(
      status: success,
      message: body['message'] ?? '',
      data: body['status'] is String ? body['status'] as String : null,
    );
  }

  @override
  Future<ApiResponse<void>> deleteOrders({required String startDate, required String endDate}) async {
    final response = await dioClient.post(
      'orders-deleted',
      data: {"start_date": startDate, "end_date": endDate},
    );
    return ApiResponse.fromJson(response.data, (json) => null);
  }

  @override
  Future<ApiResponse<void>> forgotPin({required String oldPin, required String newPin}) async {
    final response = await dioClient.post(
      ApiConstants.forgotPin,
      data: {"old_pin": oldPin, "new_pin": newPin},
    );
    return ApiResponse.fromJson(response.data, (json) => null);
  }

  @override
  Future<ApiResponse<void>> saveTableOrder(Map<String, dynamic> data) async {
    final response = await dioClient.post(ApiConstants.saveTableOrder, data: data);
    return ApiResponse.fromJson(response.data, (json) => null);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createPosOrder(Map<String, dynamic> data) async {
    final response = await dioClient.post(ApiConstants.posOrder, data: data);
    // Carries back { order_id, token_no, total } so the caller can print the
    // bill locally (keyed by the server order id for dedup).
    return ApiResponse.fromJson(
      response.data,
      (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
    );
  }

  @override
  Future<ApiResponse<void>> savePosDraft(Map<String, dynamic> data) async {
    final response = await dioClient.post(ApiConstants.posDraftSave, data: data);
    return ApiResponse.fromJson(response.data, (json) => null);
  }

  @override
  Future<ApiResponse<OrderApiModel?>> getPosDraft() async {
    final response = await dioClient.post(ApiConstants.posDraft);
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final order = (json is Map<String, dynamic>) ? json['order'] : null;
        if (order == null) return null;
        return OrderApiModel.fromDashboardJson(order as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<ApiResponse<void>> clearPosDraft() async {
    final response = await dioClient.post(ApiConstants.posDraftClear);
    return ApiResponse.fromJson(response.data, (json) => null);
  }

  @override
  Future<ApiResponse<List<PendingTableModel>>> getPendingTables() async {
    final response = await dioClient.post(ApiConstants.pendingTables);
    return ApiResponse.fromJson(
      response.data,
      (json) => (json as List).map((e) => PendingTableModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
