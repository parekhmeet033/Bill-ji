import 'menu_item_model.dart';

enum TableStatus { available, occupied, billed }

class TableModel {
  final String id;
  final String tableNumber;
  TableOrder? activeOrder;
  TableStatus status;

  TableModel({
    required this.id,
    required this.tableNumber,
    this.activeOrder,
    this.status = TableStatus.available,
  });

  bool get isOccupied => activeOrder != null && activeOrder!.items.isNotEmpty;

  TableModel copyWith({
    String? id,
    String? tableNumber,
    TableOrder? activeOrder,
    TableStatus? status,
  }) {
    return TableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      activeOrder: activeOrder ?? this.activeOrder,
      status: status ?? this.status,
    );
  }
}

class TableOrder {
  final List<TableOrderItem> items;
  final DateTime startTime;

  TableOrder({
    required this.items,
    required this.startTime,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  TableOrder copyWith({
    List<TableOrderItem>? items,
    DateTime? startTime,
  }) {
    return TableOrder(
      items: items ?? List.from(this.items),
      startTime: startTime ?? this.startTime,
    );
  }
}

class TableOrderItem {
  final MenuItemModel menuItem;
  int quantity;
  String? variant; // 'Half' or 'Full' for plate unit items

  TableOrderItem({
    required this.menuItem,
    this.quantity = 1,
    this.variant,
  });

  double get price {
    if (menuItem.unit == PriceUnit.plate) {
      return variant == 'Half' ? (menuItem.halfPrice ?? 0) : (menuItem.fullPrice ?? 0);
    }
    return menuItem.price ?? 0;
  }

  double get total => price * quantity;

  TableOrderItem copyWith({
    MenuItemModel? menuItem,
    int? quantity,
    String? variant,
  }) {
    return TableOrderItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
    );
  }
}
