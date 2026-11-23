import '../../core/utils/resource.dart';
import '../../models/order_model.dart';
import '../../models/dashboard_model.dart';
import '../../models/pagination_model.dart';
import '../../models/report_model.dart';
import '../../models/pending_table_model.dart';

abstract class OrderRepository {
  Future<Resource<List<OrderModel>>> getOrders();
  Future<Resource<DashboardData>> getDashboardData();
  Future<Resource<PaginatedData<List<OrderModel>>>> getOrdersList({
    required String status,
    required String orderType,
    required String search,
    required String startDate,
    required String endDate,
    required int page,
  });
  Future<Resource<ReportData>> getReportsAnalytics({String? userPin, String? startDate, String? endDate});
  Future<Resource<String>> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentType,
    double? upiAmount,
    double? cashAmount,
  });
  Future<Resource<void>> deleteOrders({
    required String startDate,
    required String endDate,
  });
  Future<Resource<void>> forgotPin({
    required String oldPin,
    required String newPin,
  });
  Future<Resource<void>> saveTableOrder(Map<String, dynamic> data);
  Future<Resource<Map<String, dynamic>>> createPosOrder(Map<String, dynamic> data);
  Future<Resource<void>> savePosDraft(Map<String, dynamic> data);
  Future<Resource<OrderModel?>> getPosDraft();
  Future<Resource<void>> clearPosDraft();
  Future<Resource<List<PendingTableModel>>> getPendingTables();
}
