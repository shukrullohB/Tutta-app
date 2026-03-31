import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failure.dart';
import 'api_result.dart';
import 'dio_client.dart';

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return ApiSuccess(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      return ApiFailure(_toFailure(error));
    } catch (_) {
      return const ApiFailure(
        Failure(message: 'Unknown error occurred while loading data.'),
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return ApiSuccess(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      return ApiFailure(_toFailure(error));
    } catch (_) {
      return const ApiFailure(
        Failure(message: 'Unknown error occurred while sending data.'),
      );
    }
  }

  Failure _toFailure(DioException error) {
    final payload = error.response?.data;
    String message = 'Network error. Please try again.';

    if (payload is Map<String, dynamic>) {
      final serverMessage = payload['message'];
      final detail = payload['detail'];

      if (serverMessage is String && serverMessage.isNotEmpty) {
        message = serverMessage;
      } else if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else {
        for (final entry in payload.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty && value.first is String) {
            message = value.first as String;
            break;
          }
          if (value is String && value.isNotEmpty) {
            message = value;
            break;
          }
        }
      }
    }

    return Failure(
      message: message,
      statusCode: error.response?.statusCode,
      code: error.type.name,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
