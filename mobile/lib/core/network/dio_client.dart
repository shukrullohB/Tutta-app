import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_token_provider.dart';

const _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.tutta.uz/api',
);

final dioProvider = Provider<Dio>((ref) {
  final authToken = ref.watch(authTokenProvider);

  final client = Dio(
    BaseOptions(
      baseUrl: _defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  client.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authToken != null && authToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $authToken';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ),
  );

  return client;
});
