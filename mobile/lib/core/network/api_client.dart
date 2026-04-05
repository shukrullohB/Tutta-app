import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failure.dart';
import 'api_result.dart';
import 'dio_client.dart';

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

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
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _optionsForBody(data: data, headers: headers),
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

  Future<ApiResult<Map<String, dynamic>>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _optionsForBody(data: data, headers: headers),
      );
      return ApiSuccess(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      return ApiFailure(_toFailure(error));
    } catch (_) {
      return const ApiFailure(
        Failure(message: 'Unknown error occurred while updating data.'),
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _optionsForBody(data: data, headers: headers),
      );
      return ApiSuccess(response.data ?? <String, dynamic>{});
    } on DioException catch (error) {
      return ApiFailure(_toFailure(error));
    } catch (_) {
      return const ApiFailure(
        Failure(message: 'Unknown error occurred while updating data.'),
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
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
        Failure(message: 'Unknown error occurred while deleting data.'),
      );
    }
  }

  Failure _toFailure(DioException error) {
    final payload = error.response?.data;
    final statusCode = error.response?.statusCode;
    String message = 'Network error. Please try again.';

    if (payload is Map) {
      final mapPayload = payload.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final serverMessage = mapPayload['message'];
      final detail = mapPayload['detail'];

      if (serverMessage is String && serverMessage.isNotEmpty) {
        message = serverMessage;
      } else if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (mapPayload['errors'] is Map) {
        final errors = (mapPayload['errors'] as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        );
        for (final value in errors.values) {
          final extracted = _extractMessageFromAny(value);
          if (extracted != null) {
            message = extracted;
            break;
          }
        }
      } else {
        for (final entry in mapPayload.entries) {
          final extracted = _extractMessageFromAny(entry.value);
          if (extracted != null) {
            message = extracted;
            break;
          }
        }
      }
    } else if (payload is String && payload.isNotEmpty) {
      message = payload;
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Connection timeout. Check internet and try again.';
          break;
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Request timeout. Please try again.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Secure connection failed (SSL certificate).';
          break;
        case DioExceptionType.connectionError:
          final reason = error.error?.toString().trim();
          if (reason != null && reason.isNotEmpty) {
            message = 'Cannot connect to server: $reason';
          } else {
            message = 'Cannot connect to server. Check internet connection.';
          }
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
        case DioExceptionType.badResponse:
          final fallback = error.message?.trim();
          if (fallback != null && fallback.isNotEmpty) {
            message = fallback;
          } else if (statusCode != null) {
            message = 'Server returned HTTP $statusCode.';
          }
          break;
      }
    }

    return Failure(
      message: message,
      statusCode: statusCode,
      code: error.type.name,
    );
  }

  String? _extractMessageFromAny(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String && first.isNotEmpty) {
        return first;
      }
      final converted = first?.toString().trim();
      if (converted != null && converted.isNotEmpty) {
        return converted;
      }
      return null;
    }
    if (value is Map) {
      final maybeMessage = value['message'] ?? value['detail'] ?? value['string'];
      return _extractMessageFromAny(maybeMessage);
    }
    final converted = value.toString().trim();
    if (converted.isNotEmpty) {
      return converted;
    }
    return null;
  }

  Options _optionsForBody({
    required Object? data,
    Map<String, String>? headers,
  }) {
    if (data is FormData) {
      return Options(
        headers: headers,
        contentType: 'multipart/form-data',
      );
    }
    return Options(headers: headers);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
