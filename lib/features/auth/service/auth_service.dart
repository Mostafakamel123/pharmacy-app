// ignore_for_file: unused_catch_clause

import 'package:dio/dio.dart';
import 'package:pharmacy_app/core/network/dio_client.dart';
import 'package:pharmacy_app/core/network/failure.dart';
import 'package:pharmacy_app/core/helpers/local_storage_helper.dart';
import 'package:pharmacy_app/core/constants/app_constants.dart';
import 'package:pharmacy_app/features/auth/model/auth_user.dart';

/// Authentication service interface
abstract class AuthService {
  Future<AuthUser?> login(String email, String password);
  Future<AuthUser?> register(String fullName, String email, String password);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String resetCode, String newPassword);
  Future<void> resendConfirmationEmail(String email);
  Future<void> confirmEmail(String userId, String code);
  Future<AuthUser?> getCurrentUser();
}

/// Implementation of Auth Service using Dio - Elaaj API
class AuthServiceImpl implements AuthService {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<AuthUser?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/identity/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Handle different response structures
        final userData = data['user'] ?? data['data']?['user'] ?? data;
        final accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
        final refreshToken = data['refreshToken'] ?? data['refresh_token'];

        // Save tokens
        if (accessToken != null) {
          await LocalStorageHelper.setString(
            AppConstants.authTokenKey,
            accessToken,
          );
        }
        if (refreshToken != null) {
          await LocalStorageHelper.setString(
            AppConstants.refreshTokenKey,
            refreshToken,
          );
        }

        // Save user data
        if (userData != null && userData is Map<String, dynamic>) {
          await LocalStorageHelper.setObject(AppConstants.userDataKey, userData);
        }

        // Return user
        return AuthUser.fromJson(userData as Map<String, dynamic>);
      } else {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'LOGIN_ERROR');
    }
  }

  @override
  Future<AuthUser?> register(String fullName, String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/identity/register',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // Handle different response structures
        final userData = data['user'] ?? data['data']?['user'] ?? data;
        final accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
        final refreshToken = data['refreshToken'] ?? data['refresh_token'];

        // Save tokens if provided
        if (accessToken != null) {
          await LocalStorageHelper.setString(
            AppConstants.authTokenKey,
            accessToken,
          );
        }
        if (refreshToken != null) {
          await LocalStorageHelper.setString(
            AppConstants.refreshTokenKey,
            refreshToken,
          );
        }

        // Save user data
        if (userData != null && userData is Map<String, dynamic>) {
          await LocalStorageHelper.setObject(AppConstants.userDataKey, userData);
        }

        // Return user
        return AuthUser.fromJson(userData as Map<String, dynamic>);
      } else {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'REGISTER_ERROR');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Call logout endpoint to invalidate token (optional)
      await _dio.post('/api/identity/logout').catchError((_) => null);
    } catch (e) {
      // Ignore errors during logout
    } finally {
      // Clear local storage
      await LocalStorageHelper.remove(AppConstants.authTokenKey);
      await LocalStorageHelper.remove(AppConstants.refreshTokenKey);
      await LocalStorageHelper.remove(AppConstants.userDataKey);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/api/identity/forgotPassword',
        data: {'email': email},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'PASSWORD_RESET_ERROR');
    }
  }

  @override
  Future<void> resetPassword(String email, String resetCode, String newPassword) async {
    try {
      final response = await _dio.post(
        '/api/identity/resetPassword',
        data: {
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'PASSWORD_RESET_ERROR');
    }
  }

  @override
  Future<void> resendConfirmationEmail(String email) async {
    try {
      final response = await _dio.post(
        '/api/identity/resendConfirmationEmail',
        data: {'email': email},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'VERIFICATION_ERROR');
    }
  }

  @override
  Future<void> confirmEmail(String userId, String code) async {
    try {
      final response = await _dio.get(
        '/api/identity/confirmEmail',
        queryParameters: {
          'userId': userId,
          'code': code,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'VERIFICATION_ERROR');
    }
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    try {
      final response = await _dio.get(
        '/api/identity/profile',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'] ?? data['data'] ?? data;
        return AuthUser.fromJson(userData as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

/// Create Failure from Dio response
Failure _failureFromResponse(Response response) {
  final statusCode = response.statusCode ?? 500;
  final data = response.data;

  String message = 'An error occurred';
  String code = 'ERROR_$statusCode';

  // Try to extract error message from response
  if (data is Map<String, dynamic>) {
    message = data['message'] as String? ??
              data['error'] as String? ??
              data['title'] as String? ??
              message;
    code = data['code'] as String? ?? code;
  }

  if (statusCode == 401) {
    return AuthFailure(
      message: message,
      tokenInvalid: true,
    );
  } else if (statusCode >= 400 && statusCode < 500) {
    return ValidationFailure(
      message: message,
      errors: data['errors'] as Map<String, List<String>>?,
    );
  } else if (statusCode >= 500) {
    return NetworkFailure(
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }

  return AppFailure(message: message, code: code);
}