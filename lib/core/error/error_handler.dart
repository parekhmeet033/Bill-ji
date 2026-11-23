import 'package:dio/dio.dart';
import 'failures.dart';

class ErrorHandler {
  static Failure handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkFailure('Connection timed out. Please try again.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          String message = 'Something went wrong';

          if (data is Map) {
            message = data['message']?.toString() ?? 'Something went wrong';
            
            // Handle Laravel-style validation errors (422)
            if (statusCode == 422 && data['errors'] != null) {
              final Map<String, dynamic> errors = data['errors'];
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                message = firstError.first.toString();
              }
            }
          } else if (data is String && data.isNotEmpty) {
            message = data;
          }
          
          if (statusCode == 401) return UnauthorizedFailure(message);
          if (statusCode == 422) return ValidationFailure(message);
          if (statusCode == 404) return ServerFailure('Resource not found');
          if (statusCode == 500) return ServerFailure('Internal server error');
          
          return ServerFailure(message);
        case DioExceptionType.cancel:
          return UnknownFailure('Request was cancelled');
        case DioExceptionType.connectionError:
          return NetworkFailure('No internet connection');
        default:
          return UnknownFailure('An unexpected error occurred');
      }
    } else {
      return UnknownFailure(error.toString());
    }
  }
}
