
// ignore_for_file: use_super_parameters

import 'package:Elaaj/core/network/network_exception.dart';
import 'package:dio/dio.dart';

/// Helper function to safely execute API calls and handle exceptions
/// 
/// Usage:
/// ```dart
/// try {
///   final result = await safeApiCall(() => apiEndpoints.authLogin(
///     email: 'user@example.com',
///     password: 'mypassword',
///   ));
///   // Handle success
/// } on NetworkException catch (e) {
///   // Handle network error
///   print('Error ${e.statusCode}: ${e.message}');
/// }
/// ```
Future<T> safeApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw NetworkException.fromDioException(e);
  } catch (e) {
    if (e is NetworkException) {
      rethrow;
    }
    throw NetworkException(
      message: 'An unexpected error occurred: $e',
      code: 'UNKNOWN_ERROR',
    );
  }
}

abstract class Failure {
  final String message;
  final String code;

  Failure({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'Failure: $message (Code: $code)';
}

/// Network-related failure
class NetworkFailure extends Failure {
  final int? statusCode;

  NetworkFailure({
    required String message,
    String code = 'NETWORK_ERROR',
    this.statusCode,
  }) : super(message: message, code: code);

  bool get isAuthError => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

/// Server-side validation failure
class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  ValidationFailure({
    required String message,
    this.errors,
  }) : super(message: message, code: 'VALIDATION_ERROR');

  /// Get error for a specific field
  String? getFieldError(String fieldName) {
    return errors?[fieldName]?.firstOrNull;
  }

  /// Get all error messages as a single string
  String getAllErrorsAsString() {
    if (errors == null || errors!.isEmpty) return message;
    
    final errorStrings = <String>[];
    errors!.forEach((field, messages) {
      errorStrings.add('$field: ${messages.join(', ')}');
    });
    return errorStrings.join('\n');
  }
}

/// Authentication failure
class AuthFailure extends Failure {
  final bool tokenExpired;
  final bool tokenInvalid;

  AuthFailure({
    required String message,
    this.tokenExpired = false,
    this.tokenInvalid = false,
  }) : super(message: message, code: 'AUTH_ERROR');
}

/// Generic application failure
class AppFailure extends Failure {
  AppFailure({
    required String message,
    String code = 'APP_ERROR',
  }) : super(message: message, code: code);
}

/// Offline/No internet connection failure
class OfflineFailure extends Failure {
  OfflineFailure()
      : super(
          message: 'No internet connection. Please check your network.',
          code: 'OFFLINE',
        );
}

/// Timeout failure
class TimeoutFailure extends Failure {
  TimeoutFailure({
    String message = 'Request timeout. Please try again.',
  }) : super(message: message, code: 'TIMEOUT');
}

/// Cache failure
class CacheFailure extends Failure {
  CacheFailure({
    required String message,
  }) : super(message: message, code: 'CACHE_ERROR');
}

/// Parsing/Serialization failure
class ParseFailure extends Failure {
  ParseFailure({
    required String message,
  }) : super(message: message, code: 'PARSE_ERROR');
}
