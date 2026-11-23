import '../../models/order_model.dart';

class OrderApiModel extends OrderModel {
  OrderApiModel({
    required super.id,
    required super.tokenNumber,
    required super.customerName,
    required super.customerMobile,
    required super.items,
    required super.totalAmount,
    super.subtotalAmount,
    super.gstAmount,
    super.cgstAmount,
    super.sgstAmount,
    required super.createdAt,
    required super.status,
    super.specialNote,
    super.orderType,
    super.paymentType,
    super.upiAmount,
    super.cashAmount,
  });

  factory OrderApiModel.fromJson(Map<String, dynamic> json) {
    return OrderApiModel(
      id: json['id'].toString(),
      tokenNumber: json['token_number'] ?? json['token_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      subtotalAmount: double.tryParse(json['subtotal_amount']?.toString() ?? ''),
      gstAmount: double.tryParse(json['gst_amount']?.toString() ?? ''),
      cgstAmount: double.tryParse(json['cgst_amount']?.toString() ?? ''),
      sgstAmount: double.tryParse(json['sgst_amount']?.toString() ?? ''),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      // The backend serializes order_date as a UTC ISO string, so convert it to
      // the device's local time before it is formatted for display.
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      status: OrderApiModel.mapStatus(json['status']),
      specialNote: json['special_note'] ?? json['order_note'],
      orderType: json['order_type']?.toString(),
      paymentType: json['payment_type']?.toString(),
      upiAmount: double.tryParse(json['upi_amount']?.toString() ?? ''),
      cashAmount: double.tryParse(json['cash_amount']?.toString() ?? ''),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem(
                productId: int.tryParse(e['product_id']?.toString() ?? ''),
                name: e['name'] ?? e['product_name'] ?? '',
                quantity: e['quantity']?.toString() ?? e['qty']?.toString() ?? '0',
                price: double.tryParse(e['price']?.toString() ?? '0') ?? 0,
                taxableAmount: double.tryParse(e['taxable_amount']?.toString() ?? ''),
                gstApplicable: e['gst_applicable'] == 1 || e['gst_applicable'] == '1' || e['gst_applicable'] == true,
                gstRate: double.tryParse(e['gst_rate']?.toString() ?? ''),
                gstAmount: double.tryParse(e['gst_amount']?.toString() ?? ''),
                total: double.tryParse(e['total']?.toString() ?? ''),
                unit: e['unit']?.toString(),
                note: e['note']?.toString(),
              ))
          .toList(),
    );
  }

  static OrderStatus mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return OrderStatus.pending;
      case 'running': return OrderStatus.running;
      case 'completed': return OrderStatus.completed;
      case 'dispatched': return OrderStatus.dispatched;
      default: return OrderStatus.cancelled;
    }
  }

  static OrderApiModel fromDashboardJson(Map<String, dynamic> json) {
    return OrderApiModel(
      id: json['order_id'].toString(),
      tokenNumber: json['token_no']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      customerMobile: json['customer_mobile'] ?? '',
      subtotalAmount: double.tryParse(json['subtotal_amount']?.toString() ?? ''),
      gstAmount: double.tryParse(json['gst_amount']?.toString() ?? ''),
      cgstAmount: double.tryParse(json['cgst_amount']?.toString() ?? ''),
      sgstAmount: double.tryParse(json['sgst_amount']?.toString() ?? ''),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(json['order_date'] ?? '')?.toLocal() ?? DateTime.now(),
      status: mapStatus(json['status']),
      specialNote: json['special_note'] ?? json['order_note'],
      orderType: json['order_type']?.toString(),
      paymentType: json['payment_type']?.toString(),
      upiAmount: double.tryParse(json['upi_amount']?.toString() ?? ''),
      cashAmount: double.tryParse(json['cash_amount']?.toString() ?? ''),
      items: (json['items'] as List?)
              ?.map((e) => OrderItem(
                    productId: int.tryParse(e['product_id']?.toString() ?? ''),
                    name: e['product_name'] ?? e['name'] ?? '',
                    quantity: e['quantity']?.toString() ?? e['qty']?.toString() ?? '0',
                    price: double.tryParse(e['price']?.toString() ?? '0') ?? 0,
                    taxableAmount: double.tryParse(e['taxable_amount']?.toString() ?? ''),
                    gstApplicable: e['gst_applicable'] == 1 || e['gst_applicable'] == '1' || e['gst_applicable'] == true,
                    gstRate: double.tryParse(e['gst_rate']?.toString() ?? ''),
                    gstAmount: double.tryParse(e['gst_amount']?.toString() ?? ''),
                    total: double.tryParse(e['total']?.toString() ?? '0'),
                    unit: e['unit']?.toString(),
                    note: e['note']?.toString(),
                  ))
              .toList() ??
          [],
    );
  }
}
