import '../../models/dashboard_model.dart';
import '../../models/order_model.dart';
import 'order_api_model.dart';

class DashboardApiModel extends DashboardData {
  DashboardApiModel({
    required super.userId,
    super.userName,
    super.profileBanner,
    required super.runningToken,
    required super.todayTotalOrders,
    required super.todayPendingOrders,
    required super.todayCompletedOrders,
    required super.todayDispatchedOrders,
    super.generatedCode,
    super.slug,
    required super.oprationModeStatus,
    required super.numberOfTables,
    required super.recentOrders,
  });

  factory DashboardApiModel.fromJson(Map<String, dynamic> json) {
    return DashboardApiModel(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'],
      profileBanner: json['profile_banner'],
      runningToken: json['running_token']?.toString() ?? '0',
      todayTotalOrders: json['today_total_orders'] ?? 0,
      todayPendingOrders: json['today_pending_orders'] ?? 0,
      todayCompletedOrders: json['today_completed_orders'] ?? 0,
      todayDispatchedOrders: json['today_dispatched_orders'] ?? 0,
      generatedCode: json['generated_code'],
      slug: json['slug'],
      oprationModeStatus: json['opration_mode_status']?.toString() ?? 'both',
      numberOfTables: int.tryParse(json['number_of_tables']?.toString() ?? '') ?? 10,
      recentOrders: (json['recent_orders'] as List?)
              ?.map<OrderModel>((e) => OrderApiModel.fromDashboardJson(e as Map<String, dynamic>))
              .toList() ??
          <OrderModel>[],
    );
  }
}
