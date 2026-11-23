import 'order_model.dart';

class DashboardData {
  final int userId;
  final String? userName;
  final String? profileBanner;
  final String runningToken;
  final int todayTotalOrders;
  final int todayPendingOrders;
  final int todayCompletedOrders;
  final int todayDispatchedOrders;
  final String? generatedCode;
  final String? slug;
  final String oprationModeStatus;
  final int numberOfTables;
  final List<OrderModel> recentOrders;

  DashboardData({
    required this.userId,
    this.userName,
    this.profileBanner,
    required this.runningToken,
    required this.todayTotalOrders,
    required this.todayPendingOrders,
    required this.todayCompletedOrders,
    required this.todayDispatchedOrders,
    this.generatedCode,
    this.slug,
    required this.oprationModeStatus,
    required this.numberOfTables,
    required this.recentOrders,
  });
}
