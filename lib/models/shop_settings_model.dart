class ShopSettingsModel {
  final int id;
  final int userId;
  final bool isShopOpen;
  final String morningStart;
  final String morningEnd;
  final String afternoonStart;
  final String afternoonEnd;
  final String eveningStart;
  final String eveningEnd;
  final bool categoryDisplay;
  final String? generatedCode;
  final String oprationModeStatus;
  final int numberOfTables;
  final bool isGstEnabled;
  final String? gstin;
  final String? legalBusinessName;
  final String? businessAddress;
  final String? state;
  final String? stateCode;

  ShopSettingsModel({
    required this.id,
    required this.userId,
    required this.isShopOpen,
    required this.morningStart,
    required this.morningEnd,
    required this.afternoonStart,
    required this.afternoonEnd,
    required this.eveningStart,
    required this.eveningEnd,
    required this.categoryDisplay,
    this.generatedCode,
    required this.oprationModeStatus,
    required this.numberOfTables,
    this.isGstEnabled = false,
    this.gstin,
    this.legalBusinessName,
    this.businessAddress,
    this.state,
    this.stateCode,
  });

  factory ShopSettingsModel.fromJson(Map<String, dynamic> json) {
    return ShopSettingsModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      isShopOpen: (json['shop_open'] == 0 || json['shop_open'] == "0"),
      morningStart: _formatTime(json['morning_start']),
      morningEnd: _formatTime(json['morning_end']),
      afternoonStart: _formatTime(json['afternoon_start']),
      afternoonEnd: _formatTime(json['afternoon_end']),
      eveningStart: _formatTime(json['evening_start']),
      eveningEnd: _formatTime(json['evening_end']),
      categoryDisplay: json['category_display'] == 1 || json['category_display'] == "1",
      generatedCode: json['generated_code']?.toString(),
      oprationModeStatus: json['opration_mode_status']?.toString() ?? 'both',
      numberOfTables: int.tryParse(json['number_of_tables']?.toString() ?? '5') ?? 5,
      isGstEnabled: json['gst_enabled'] == 1 || json['gst_enabled'] == '1' || json['gst_enabled'] == true,
      gstin: json['gstin']?.toString(),
      legalBusinessName: json['legal_business_name']?.toString(),
      businessAddress: json['business_address']?.toString(),
      state: json['state']?.toString(),
      stateCode: json['state_code']?.toString(),
    );
  }

  static String _formatTime(dynamic time) {
    if (time == null) return "00:00";
    String timeStr = time.toString();
    if (timeStr.contains(':')) {
      List<String> parts = timeStr.split(':');
      if (parts.length >= 2) {
        return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
      }
    }
    return timeStr;
  }
}
