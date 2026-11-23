import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';

class TableProvider with ChangeNotifier {
  List<TableModel> _tables = [];
  List<TableModel> get tables => _tables;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TableProvider() {
    _loadTables();
  }

  Future<void> _loadTables() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final tablesJson = prefs.getString('saved_tables');
      if (tablesJson != null) {
        final List<dynamic> decoded = jsonDecode(tablesJson);
        _tables = decoded.map((item) {
          return TableModel(
            id: item['id'],
            tableNumber: item['tableNumber'],
            status: TableStatus.values.firstWhere(
              (e) => e.toString() == (item['status'] ?? 'TableStatus.available'),
              orElse: () => TableStatus.available
            ),
          );
        }).toList();
      } else {
        // Initialize with some default tables
        _tables = List.generate(12, (i) => TableModel(
          id: '${i + 1}',
          tableNumber: '${i + 1}',
          status: TableStatus.available,
        ));
      }
    } catch (e) {
      debugPrint('Error loading tables: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTables() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tablesData = _tables.map((t) => {
        'id': t.id,
        'tableNumber': t.tableNumber,
        'status': t.status.toString(),
      }).toList();
      await prefs.setString('saved_tables', jsonEncode(tablesData));
    } catch (e) {
      debugPrint('Error saving tables: $e');
    }
  }

  void addTable(String number) {
    final newTable = TableModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableNumber: number,
    );
    _tables.add(newTable);
    _saveTables();
    notifyListeners();
  }

  void editTable(String id, String newNumber) {
    final index = _tables.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(tableNumber: newNumber);
      _saveTables();
      notifyListeners();
    }
  }

  void deleteTable(String id) {
    _tables.removeWhere((t) => t.id == id);
    _saveTables();
    notifyListeners();
  }

  void startOrder(String tableId) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1 && _tables[index].activeOrder == null) {
      _tables[index] = _tables[index].copyWith(
        activeOrder: TableOrder(items: [], startTime: DateTime.now()),
        status: TableStatus.occupied,
      );
      notifyListeners();
    }
  }

  void addItemToOrder(String tableId, MenuItemModel item, {String? variant}) {
    final tableIndex = _tables.indexWhere((t) => t.id == tableId);
    if (tableIndex == -1) return;

    if (_tables[tableIndex].activeOrder == null) {
      startOrder(tableId);
    }

    final activeOrder = _tables[tableIndex].activeOrder!;
    final itemIndex = activeOrder.items.indexWhere(
      (i) => i.menuItem.id == item.id && i.variant == variant
    );

    if (itemIndex != -1) {
      activeOrder.items[itemIndex].quantity += 1;
    } else {
      activeOrder.items.add(TableOrderItem(menuItem: item, quantity: 1, variant: variant));
    }
    notifyListeners();
  }

  void updateItemQuantity(String tableId, String menuItemId, int delta, {String? variant}) {
    final tableIndex = _tables.indexWhere((t) => t.id == tableId);
    if (tableIndex == -1 || _tables[tableIndex].activeOrder == null) return;

    final activeOrder = _tables[tableIndex].activeOrder!;
    final itemIndex = activeOrder.items.indexWhere(
      (i) => i.menuItem.id == menuItemId && i.variant == variant
    );

    if (itemIndex != -1) {
      activeOrder.items[itemIndex].quantity += delta;
      if (activeOrder.items[itemIndex].quantity <= 0) {
        activeOrder.items.removeAt(itemIndex);
      }
      notifyListeners();
    }
  }

  void removeItemFromOrder(String tableId, String menuItemId, {String? variant}) {
    final tableIndex = _tables.indexWhere((t) => t.id == tableId);
    if (tableIndex == -1 || _tables[tableIndex].activeOrder == null) return;

    _tables[tableIndex].activeOrder!.items.removeWhere(
      (i) => i.menuItem.id == menuItemId && i.variant == variant
    );
    notifyListeners();
  }

  void updateStatus(String tableId, TableStatus status) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      _tables[index] = _tables[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void clearOrder(String tableId) {
    final index = _tables.indexWhere((t) => t.id == tableId);
    if (index != -1) {
      _tables[index].activeOrder = null;
      _tables[index] = _tables[index].copyWith(status: TableStatus.available);
      notifyListeners();
    }
  }

  void syncTablesWithCount(int count) {
    if (_tables.length == count) return;
    
    if (_tables.length < count) {
      // Add more tables
      for (int i = _tables.length; i < count; i++) {
        final tableNumber = (i + 1).toString();
        _tables.add(TableModel(
          id: tableNumber,
          tableNumber: tableNumber,
          status: TableStatus.available,
        ));
      }
    } else {
      // Remove extra tables, but only if they are not occupied
      _tables.removeWhere((t) => int.parse(t.tableNumber) > count && !t.isOccupied);
    }
    _saveTables();
    notifyListeners();
  }
}
