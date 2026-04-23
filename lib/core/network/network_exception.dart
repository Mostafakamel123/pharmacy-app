import 'package:dio/dio.dart';

/// Custom exception for network-related errors
/// 
/// This class wraps different types of network errors (connection, server, etc.)
/// and provides a unified way to handle them throughout the app.
class NetworkException implements Exception {
  final String message;
  final String? code;
  final DioException? originalException;
  final int? statusCode;

  NetworkException({
    required this.message,
    this.code,
    this.originalException,
    this.statusCode,
  });

  /// Factory constructor to create NetworkException from DioException
  factory NetworkException.fromDioException(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          message: 'Connection timeout. Please try again.',
          code: 'CONNECTION_TIMEOUT',
          originalException: dioError,
          statusCode: null,
        );

      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Request timeout. Please try again.',
          code: 'SEND_TIMEOUT',
          originalException: dioError,
          statusCode: null,
        );

      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'Response timeout. Please try again.',
          code: 'RECEIVE_TIMEOUT',
          originalException: dioError,
          statusCode: null,
        );

      case DioExceptionType.badResponse:
        return NetworkException(
          message: _getResponseErrorMessage(dioError),
          code: 'BAD_RESPONSE',
          originalException: dioError,
          statusCode: dioError.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled.',
          code: 'REQUEST_CANCELLED',
          originalException: dioError,
          statusCode: null,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No internet connection. Please check your network.',
          code: 'CONNECTION_ERROR',
          originalException: dioError,
          statusCode: null,
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: 'An unexpected error occurred. Please try again.',
          code: 'UNKNOWN_ERROR',
          originalException: dioError,
          statusCode: null,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Certificate verification failed.',
          code: 'BAD_CERTIFICATE',
          originalException: dioError,
          statusCode: null,
        );
    }
  }

  /// Get detailed error message from response
  static String _getResponseErrorMessage(DioException dioError) {
    final statusCode = dioError.response?.statusCode;

    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. This resource already exists.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return dioError.response?.data['message'] ??
            'An error occurred. Please try again.';
    }
  }

  /// Check if this is an authentication error
  bool get isAuthError =>
      statusCode == 401 || code == 'UNAUTHORIZED' || code == 'TOKEN_EXPIRED';

  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Check if this is a client error (4xx)
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Check if this is a network connectivity error
  bool get isNetworkError =>
      code == 'CONNECTION_ERROR' ||
      code == 'CONNECTION_TIMEOUT' ||
      code == 'SEND_TIMEOUT' ||
      code == 'RECEIVE_TIMEOUT';

  @override
  String toString() => 'NetworkException: $message (Code: $code, Status: $statusCode)';
}
