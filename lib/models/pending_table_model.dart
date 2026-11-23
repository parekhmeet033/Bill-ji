class PendingTableModel {
  final String orderId;
  final int tableNo;
  final String customerName;
  final String customerMobile;
  final String orderNote;
  final double totalAmount;
  final DateTime? createdAt;
  final List<PendingTableItem> items;

  PendingTableModel({
    this.orderId = '',
    required this.tableNo,
    required this.customerName,
    required this.customerMobile,
    required this.orderNote,
    required this.totalAmount,
    this.createdAt,
    required this.items,
  });

  factory PendingTableModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)
            ?.map((e) => PendingTableItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PendingTableModel(
      orderId: json['order_id']?.toString() ?? '',
      tableNo: json['table_no'] is int ? json['table_no'] : int.tryParse(json['table_no']?.toString() ?? '0') ?? 0,
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      orderNote: json['order_note'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      createdAt: itemsList.isNotEmpty ? itemsList.first.createdAt : null,
      items: itemsList,
    );
  }
}

class PendingTableItem {
  final int productId;
  final String productName;
  final String? unit;
  final double qty;
  final double price;
  final double total;
  final String? note;
  final DateTime? createdAt;

  PendingTableItem({
    required this.productId,
    required this.productName,
    this.unit,
    required this.qty,
    required this.price,
    required this.total,
    this.note,
    this.createdAt,
  });

  factory PendingTableItem.fromJson(Map<String, dynamic> json) {
    return PendingTableItem(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      unit: json['unit']?.toString(),
      qty: double.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
