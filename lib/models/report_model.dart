class ReportData {
  final double todayRevenue;
  final double totalSales;
  final int totalOrders;
  final int ordersCancelled;
  final double weeklySales;
  final double todayUpiPayment;
  final double todayCashPayment;
  final double totalUpiSales;
  final double totalCashSales;

  ReportData({
    required this.todayRevenue,
    required this.totalSales,
    required this.totalOrders,
    required this.ordersCancelled,
    required this.weeklySales,
    required this.todayUpiPayment,
    required this.todayCashPayment,
    required this.totalUpiSales,
    required this.totalCashSales,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      todayRevenue: double.tryParse(json['today_revenue'].toString()) ?? 0,
      totalSales: double.tryParse(json['total_sales'].toString()) ?? 0,
      totalOrders: int.tryParse(json['total_orders'].toString()) ?? 0,
      ordersCancelled: int.tryParse(json['orders_cancelled'].toString()) ?? 0,
      weeklySales: double.tryParse(json['weekly_sales'].toString()) ?? 0,
      todayUpiPayment: double.tryParse(json['today_upi_payment']?.toString() ?? '0') ?? 0,
      todayCashPayment: double.tryParse(json['today_cash_payment']?.toString() ?? '0') ?? 0,
      totalUpiSales: double.tryParse(json['total_upi_sales']?.toString() ?? '0') ?? 0,
      totalCashSales: double.tryParse(json['total_cash_sales']?.toString() ?? '0') ?? 0,
    );
  }
}
