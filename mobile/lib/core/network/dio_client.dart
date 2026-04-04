import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_token_provider.dart';

const _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://tutta-app-production.up.railway.app/api',
);

final dioProvider = Provider<Dio>((ref) {
  final authToken = ref.watch(authTokenProvider);

  final client = Dio(
    BaseOptions(
      baseUrl: _defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  client.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/auth/google')) {
          print('[AUTH_TRACE] HTTP -> ${options.method} ${options.uri}');
        }
        if (authToken != null && authToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $authToken';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.requestOptions.path.contains('/auth/google')) {
          print('[AUTH_TRACE] HTTP <- ${response.statusCode} ${response.requestOptions.uri}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.requestOptions.path.contains('/auth/google')) {
          print(
            '[AUTH_TRACE] HTTP xx type=${error.type.name} status=${error.response?.statusCode} url=${error.requestOptions.uri}',
          );
        }
        handler.next(error);
      },
    ),
  );

  return client;
});
