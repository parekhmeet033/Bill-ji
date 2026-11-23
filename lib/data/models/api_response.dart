import '../../models/pagination_model.dart';

class ApiResponse<T> {
  final bool status;
  final String message;
  final String? token;
  final T? data;
  final Pagination? pagination;

  ApiResponse({
    required this.status,
    required this.message,
    this.token,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    // Prefer the `success` bool field; fall back to `status` only when it is a bool.
    final rawSuccess = json['success'];
    final rawStatus = json['status'];
    final bool successFlag = rawSuccess is bool
        ? rawSuccess
        : (rawStatus is bool ? rawStatus : false);

    return ApiResponse<T>(
      status: successFlag,
      message: json['message'] ?? '',
      token: json['token'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null,
    );
  }
}
