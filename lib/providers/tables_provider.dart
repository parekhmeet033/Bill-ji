import 'package:flutter/material.dart';
import '../models/table_model.dart';

class TablesProvider extends ChangeNotifier {
  TableStatus? _filter;

  TableStatus? get filter => _filter;

  void setFilter(TableStatus? status) {
    if (_filter == status) {
      _filter = null;
    } else {
      _filter = status;
    }
    notifyListeners();
  }

  void reset() {
    _filter = null;
    notifyListeners();
  }
}
