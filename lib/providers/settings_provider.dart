import 'dart:math';
import 'package:flutter/material.dart';
import '../core/services/printer_service.dart';
import '../models/shop_settings_model.dart';
import '../presentation/providers/auth_provider.dart';
import 'order_provider.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isShopOpen = true;
  bool _isAlertToneOn = true;
  bool _isNotificationOn = true;
  bool _isCategoryDisplayOn = true;
  bool _isKdsEnabled = false;
  bool _isQrEnabled = false;
  bool _isGoPosEnabled = true;
  String _upiId = '';
  String _generatedCode = '';
  
  String _morningStart = "09:00";
  String _morningEnd = "12:00";
  String _afternoonStart = "12:00";
  String _afternoonEnd = "17:00";
  String _eveningStart = "17:00";
  String _eveningEnd = "22:00";

  // GST Settings
  bool _isGstEnabled = false;
  String _gstin = '';
  String _legalBusinessName = '';
  String _businessAddress = '';
  String _state = '';
  String _stateCode = '';

  // Getters
  bool get isShopOpen => _isShopOpen;
  bool get isAlertToneOn => _isAlertToneOn;
  bool get isNotificationOn => _isNotificationOn;
  bool get isCategoryDisplayOn => _isCategoryDisplayOn;
  bool get isKdsEnabled => _isKdsEnabled;
  bool get isQrEnabled => _isQrEnabled;
  bool get isGoPosEnabled => _isGoPosEnabled;
  String get upiId => _upiId;
  String get generatedCode => _generatedCode;
  
  String get morningStart => _morningStart;
  String get morningEnd => _morningEnd;
  String get afternoonStart => _afternoonStart;
  String get afternoonEnd => _afternoonEnd;
  String get eveningStart => _eveningStart;
  String get eveningEnd => _eveningEnd;

  bool get isGstEnabled => _isGstEnabled;
  String get gstin => _gstin;
  String get legalBusinessName => _legalBusinessName;
  String get businessAddress => _businessAddress;
  String get state => _state;
  String get stateCode => _stateCode;

  void init(AuthProvider authProvider) {
    _isAlertToneOn = authProvider.isAlertToneOn;
    _isNotificationOn = authProvider.isNotificationOn;
    _isKdsEnabled = authProvider.isKdsEnabled;
    _isQrEnabled = authProvider.isQrEnabled;
    _isGoPosEnabled = authProvider.isGoPosEnabled;
    _upiId = authProvider.upiId;
    
    if (authProvider.shopSettings != null) {
      final settings = authProvider.shopSettings!;
      _isShopOpen = settings.isShopOpen;
      _isCategoryDisplayOn = settings.categoryDisplay;
      _morningStart = settings.morningStart;
      _morningEnd = settings.morningEnd;
      _afternoonStart = settings.afternoonStart;
      _afternoonEnd = settings.afternoonEnd;
      _eveningStart = settings.eveningStart;
      _eveningEnd = settings.eveningEnd;
      _generatedCode = settings.generatedCode ?? '';
      _isGstEnabled = settings.isGstEnabled;
      _gstin = settings.gstin ?? '';
      _legalBusinessName = settings.legalBusinessName ?? '';
      _businessAddress = settings.businessAddress ?? '';
      _state = settings.state ?? '';
      _stateCode = settings.stateCode ?? '';
    }

    // Keep the printer's copy of the GST details in sync so auto-printed
    // receipts (e.g. takeaway orders via the realtime queue) show the GSTIN.
    PrinterService().setGstDetails(enabled: _isGstEnabled, gstin: _gstin);
  }

  void setShopOpen(bool value) {
    _isShopOpen = value;
    notifyListeners();
  }

  void setCategoryDisplay(bool value) {
    _isCategoryDisplayOn = value;
    notifyListeners();
  }

  void setAlertTone(bool value) {
    _isAlertToneOn = value;
    notifyListeners();
  }

  void setNotification(bool value) {
    _isNotificationOn = value;
    notifyListeners();
  }

  void setKdsEnabled(bool value) {
    _isKdsEnabled = value;
    notifyListeners();
  }

  void setQrEnabled(bool value) {
    _isQrEnabled = value;
    notifyListeners();
  }

  void setGoPosEnabled(bool value) {
    _isGoPosEnabled = value;
    notifyListeners();
  }

  void setUpiId(String value) {
    _upiId = value;
    notifyListeners();
  }

  void setGeneratedCode(String value) {
    _generatedCode = value;
    notifyListeners();
  }

  void setGstEnabled(bool value) {
    _isGstEnabled = value;
    notifyListeners();
  }

  void setGstin(String value) {
    _gstin = value;
    notifyListeners();
  }

  void setLegalBusinessName(String value) {
    _legalBusinessName = value;
    notifyListeners();
  }

  void setBusinessAddress(String value) {
    _businessAddress = value;
    notifyListeners();
  }

  void setStateName(String value) {
    _state = value;
    notifyListeners();
  }

  void setStateCode(String value) {
    _stateCode = value;
    notifyListeners();
  }

  void generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String result = '';
    for (int i = 0; i < 16; i++) {
      result += chars[random.nextInt(chars.length)];
    }
    _generatedCode = result;
    notifyListeners();
  }

  void clearGeneratedCode() {
    _generatedCode = '';
    notifyListeners();
  }

  void updateMorningSlot(String start, String end) {
    _morningStart = start;
    _morningEnd = end;
    notifyListeners();
  }

  void updateAfternoonSlot(String start, String end) {
    _afternoonStart = start;
    _afternoonEnd = end;
    notifyListeners();
  }

  void updateEveningSlot(String start, String end) {
    _eveningStart = start;
    _eveningEnd = end;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  Future<bool> saveSettings(AuthProvider authProvider, OrderProvider orderProvider) async {
    final currentId = authProvider.shopSettings?.id ?? 0;
    final currentUserId = authProvider.shopSettings?.userId ?? 0;

    final settings = ShopSettingsModel(
      id: currentId,
      userId: currentUserId,
      isShopOpen: _isShopOpen,
      morningStart: _morningStart,
      morningEnd: _morningEnd,
      afternoonStart: _afternoonStart,
      afternoonEnd: _afternoonEnd,
      eveningStart: _eveningStart,
      eveningEnd: _eveningEnd,
      categoryDisplay: _isCategoryDisplayOn,
      generatedCode: _generatedCode,
      oprationModeStatus: authProvider.restaurantMode.toLowerCase(),
      numberOfTables: authProvider.tableCount,
      isGstEnabled: _isGstEnabled,
      gstin: _gstin,
      legalBusinessName: _legalBusinessName,
      businessAddress: _businessAddress,
      state: _state,
      stateCode: _stateCode,
    );

    final success = await authProvider.updateShopSettings(settings);
    if (success) {
      await authProvider.setKdsEnabled(_isKdsEnabled);
      await authProvider.setQrEnabled(_isQrEnabled);
      await authProvider.setGoPosEnabled(_isGoPosEnabled);
      await authProvider.setUpiId(_upiId);
      await PrinterService().setQrSettings(_isQrEnabled, _upiId);
      PrinterService().setGstDetails(enabled: _isGstEnabled, gstin: _gstin);
      orderProvider.fetchDashboard();
    }
    return success;
  }
}
