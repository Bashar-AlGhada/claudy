import 'package:claudy/core/http/interceptors/rate_limit_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.interceptors.addAll([
    RateLimitInterceptor(),
    LogInterceptor(requestBody: false, responseBody: false),
  ]);
  return dio;
});

