import 'package:flutter/material.dart';

class OrderDetailsProvider extends ChangeNotifier {
  bool _isPrinting = false;
  bool get isPrinting => _isPrinting;

  void setPrinting(bool value) {
    _isPrinting = value;
    notifyListeners();
  }
}
