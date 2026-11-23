enum OrderStatus { pending, running, completed, dispatched, cancelled }

class OrderModel {
  final String id;
  final String tokenNumber;
  final String customerName;
  final String customerMobile;
  final List<OrderItem> items;
  final double totalAmount;
  final double? subtotalAmount;
  final double? gstAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final DateTime createdAt;
  final OrderStatus status;
  final String? specialNote;
  final String? orderType;
  final String? paymentType;
  final double? upiAmount;
  final double? cashAmount;

  OrderModel({
    required this.id,
    required this.tokenNumber,
    required this.customerName,
    required this.customerMobile,
    required this.items,
    required this.totalAmount,
    this.subtotalAmount,
    this.gstAmount,
    this.cgstAmount,
    this.sgstAmount,
    required this.createdAt,
    required this.status,
    this.specialNote,
    this.orderType,
    this.paymentType,
    this.upiAmount,
    this.cashAmount,
  });
}

class OrderItem {
  final int? productId;
  final String name;
  final String quantity;
  final double price;
  final double? taxableAmount;
  final bool gstApplicable;
  final double? gstRate;
  final double? gstAmount;
  final double? total;
  final String? unit;
  final String? note;

  OrderItem({
    this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.taxableAmount,
    this.gstApplicable = false,
    this.gstRate,
    this.gstAmount,
    this.total,
    this.unit,
    this.note,
  });
}
