import 'package:flutter/material.dart';
import '../models/order_model.dart';

class KdsItem {
  final String name;
  final double totalQuantity;
  final String? unit;
  final List<OrderModel> associatedOrders;

  KdsItem({
    required this.name,
    required this.totalQuantity,
    this.unit,
    required this.associatedOrders,
  });
}

class KdsProvider extends ChangeNotifier {
  List<KdsItem> _aggregatedItems = [];
  List<KdsItem> get aggregatedItems => _aggregatedItems;

  void updateKds(List<OrderModel> orders) {
    // We only care about pending and running orders for KDS
    final activeOrders = orders.where((o) => 
      o.status == OrderStatus.pending || o.status == OrderStatus.running
    ).toList();

    final Map<String, List<OrderModel>> itemMap = {};
    final Map<String, double> quantityMap = {};
    final Map<String, String?> unitMap = {};

    for (var order in activeOrders) {
      for (var item in order.items) {
        final key = item.name.trim();
        
        // Track orders associated with this item
        itemMap.putIfAbsent(key, () => []).add(order);
        
        // Accumulate quantities
        final qty = double.tryParse(item.quantity) ?? 0;
        quantityMap[key] = (quantityMap[key] ?? 0) + qty;
        
        // Track unit (assuming items with same name have same unit)
        unitMap[key] = item.unit;
      }
    }

    _aggregatedItems = itemMap.keys.map((name) {
      return KdsItem(
        name: name,
        totalQuantity: quantityMap[name]!,
        unit: unitMap[name],
        associatedOrders: itemMap[name]!,
      );
    }).toList();

    // Sort by quantity descending or name? Let's do name for now.
    _aggregatedItems.sort((a, b) => a.name.compareTo(b.name));

    notifyListeners();
  }
}
