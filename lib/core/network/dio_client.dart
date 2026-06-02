// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/config/env_config.dart';
import 'package:pharmacy_app/core/constants/app_constants.dart';
import 'package:pharmacy_app/core/helpers/local_storage_helper.dart';

final dioClientProvider = Provider<Dio>((ref) {
  return DioClient.instance.dio;
});

/// Singleton Dio client with configuration
class DioClient {
  static final DioClient _instance = DioClient._internal();

  late final Dio _dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _dio = _initializeDio();
  }

  static DioClient get instance => _instance;

  Dio get dio => _dio;

  /// Initialize Dio with base configuration
  Dio _initializeDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: EnvConfig.connectionTimeout),
        receiveTimeout: Duration(milliseconds: EnvConfig.receiveTimeout),
        sendTimeout: Duration(milliseconds: EnvConfig.requestTimeout),
        contentType: 'application/json',
        validateStatus: (status) {
          // Accept all status codes and handle them manually
          // This prevents Dio from throwing on non-2xx responses
          return status != null && status < 500;
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(_AuthInterceptor());
    if (EnvConfig.enableLogging) {
      dio.interceptors.add(_LoggingInterceptor());
    }
    dio.interceptors.add(_ErrorInterceptor());

    return dio;
  }
}

/// Authentication interceptor
/// 
/// Adds auth token to requests and handles token refresh
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get auth token from local storage
    final token = await LocalStorageHelper.getString(AppConstants.authTokenKey);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add other default headers
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  /// Helper to perform token refresh using a clean Dio instance to avoid recursion
  Future<String?> _performTokenRefresh(String baseUrl) async {
    try {
      final refreshToken =
          await LocalStorageHelper.getString(AppConstants.refreshTokenKey);
      final expiredToken =
          await LocalStorageHelper.getString(AppConstants.authTokenKey);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        // Create a dedicated Dio instance without interceptors to avoid loops
        final dio = Dio(BaseOptions(
          baseUrl: baseUrl.isNotEmpty ? baseUrl : EnvConfig.apiBaseUrl,
          contentType: 'application/json',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

        final response = await dio.post(
          '/api/Auth/refresh-token',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {
            'Accept': 'application/json',
            if (expiredToken != null) 'Authorization': 'Bearer $expiredToken',
          }),
        );

        if (response.statusCode == 200) {
          final newToken = response.data['token'] as String?;
          final newRefreshToken = response.data['refreshToken'] as String?;

          if (newToken != null && newToken.isNotEmpty) {
            // Save new tokens
            await LocalStorageHelper.setString(
              AppConstants.authTokenKey,
              newToken,
            );
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await LocalStorageHelper.setString(
                AppConstants.refreshTokenKey,
                newRefreshToken,
              );
            }
            return newToken;
          }
        }
      }
    } catch (e) {
      print('DEBUG: Error in _AuthInterceptor refreshing token: $e');
    }
    return null;
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - refresh token
    // (since validateStatus: status < 500 allows 401 to be processed as successful)
    if (response.statusCode == 401 &&
        !response.requestOptions.path.contains('/api/Auth/refresh-token')) {
      final newToken = await _performTokenRefresh(response.requestOptions.baseUrl);

      if (newToken != null) {
        // Retry original request with new token
        response.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await DioClient.instance.dio.request(
            response.requestOptions.path,
            options: Options(
              method: response.requestOptions.method,
              headers: response.requestOptions.headers,
            ),
            data: response.requestOptions.data,
          );
          return handler.resolve(retryResponse);
        } catch (e) {
          print('DEBUG: Retry request in onResponse failed: $e');
        }
      }

      // Token refresh failed or no refresh token - clear auth
      await LocalStorageHelper.remove(AppConstants.authTokenKey);
      await LocalStorageHelper.remove(AppConstants.refreshTokenKey);
      await LocalStorageHelper.remove(AppConstants.userDataKey);

      // Convert 401 response to a rejected DioException to prevent type casting crashes in the caller
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          message: 'Session expired. Please login again.',
        ),
      );
    }

    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - refresh token
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/api/Auth/refresh-token')) {
      final newToken = await _performTokenRefresh(err.requestOptions.baseUrl);

      if (newToken != null) {
        // Retry original request with new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final retryResponse = await DioClient.instance.dio.request(
            err.requestOptions.path,
            options: Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            ),
            data: err.requestOptions.data,
          );
          return handler.resolve(retryResponse);
        } catch (e) {
          print('DEBUG: Retry request in onError failed: $e');
        }
      }

      // Token refresh failed or no refresh token - clear auth
      await LocalStorageHelper.remove(AppConstants.authTokenKey);
      await LocalStorageHelper.remove(AppConstants.refreshTokenKey);
      await LocalStorageHelper.remove(AppConstants.userDataKey);
    }

    return handler.next(err);
  }
}

/// Error handling interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Error handling can be done here if needed
    return handler.next(err);
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (EnvConfig.enableNetworkDebug) {
      print('==> REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers:');
      options.headers.forEach((k, v) => print('$k: $v'));
      if (options.data != null) {
        print('Body: ${options.data}');
      }
      print('<== END HTTP REQUEST');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (EnvConfig.enableNetworkDebug) {
      print('==> RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      print('Headers:');
      response.headers.forEach((k, v) => print('$k: $v'));
      print('Body: ${response.data}');
      print('<== END HTTP RESPONSE');
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (EnvConfig.enableNetworkDebug) {
      print('==> ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('Message: ${err.message}');
      if (err.response != null) {
        print('Response: ${err.response?.data}');
      }
      print('<== END ERROR');
    }
    return handler.next(err);
  }
}
