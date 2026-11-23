import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/api_constants.dart';
import '../localization/locale_service.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add Token to Header automatically
    final tokenBox = Hive.box(CacheConstants.tokenBox);
    final String? token = tokenBox.get(CacheConstants.authToken);

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers['token'] = token; // Added literal 'token' header
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    // Tell the backend which language to localize messages/menu names in.
    options.headers['Accept-Language'] = LocaleService.currentCode;

    if (kDebugMode) {
      log('--- API REQUEST ---');
      log('URL: ${options.uri}');
      log('Method: ${options.method}');
      log('Headers: ${options.headers}');
      log('Data: ${options.data}');
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      log('--- API RESPONSE ---');
      log('Status Code: ${response.statusCode}');
      log('Data: ${response.data}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      log('--- API ERROR ---');
      log('URL: ${err.requestOptions.uri}');
      log('Error: ${err.message}');
      log('Response: ${err.response?.data}');
    }

    // Handle 401 Unauthorized (Token expired)
    if (err.response?.statusCode == 401) {
      // Logic to logout or refresh token
      log('Token Expired - Need to login again or refresh');
    }

    return handler.next(err);
  }
}
