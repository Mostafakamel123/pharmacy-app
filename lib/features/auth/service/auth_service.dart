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
  Future<AuthUser?> register(String name, String email, String password);
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> resetPassword(String token, String newPassword);
  Future<void> resendVerificationEmail();
  Future<void> verifyEmail(String token);
  Future<AuthUser?> getCurrentUser();
}

/// Implementation of Auth Service using Dio
class AuthServiceImpl implements AuthService {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<AuthUser?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        if (data['token'] != null) {
          await LocalStorageHelper.setString(
            AppConstants.authTokenKey,
            data['token'],
          );
        }
        if (data['refreshToken'] != null) {
          await LocalStorageHelper.setString(
            AppConstants.refreshTokenKey,
            data['refreshToken'],
          );
        }

        // Return user
        return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
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
  Future<AuthUser?> register(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;

        // Save tokens if provided
        if (data['token'] != null) {
          await LocalStorageHelper.setString(
            AppConstants.authTokenKey,
            data['token'],
          );
        }
        if (data['refreshToken'] != null) {
          await LocalStorageHelper.setString(
            AppConstants.refreshTokenKey,
            data['refreshToken'],
          );
        }

        // Return user
        return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
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
      // Call logout endpoint to invalidate token
      await _dio.post('/auth/logout');
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
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
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
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': newPassword,
        },
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
  Future<void> resendVerificationEmail() async {
    try {
      final response = await _dio.post('/auth/resend-verification');

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
  Future<void> verifyEmail(String token) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'token': token},
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
      final response = await _dio.get('/auth/me');

      if (response.statusCode == 200) {
        final data = response.data;
        return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
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