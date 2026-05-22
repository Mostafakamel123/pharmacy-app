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
        
        // Handle different response structures - check if it's a success response
        Map<String, dynamic> userData;
        String? accessToken;
        String? refreshToken;
        
        // Check if response has success flag
        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            // Response format: {success: true, message: "...", data: {...}}
            userData = data['data'] as Map<String, dynamic>? ?? data;
            accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
            refreshToken = data['refreshToken'] ?? data['refresh_token'];
          } else if (data.containsKey('user')) {
            // Response format: {user: {...}, accessToken: "..."}
            userData = data['user'] as Map<String, dynamic>;
            accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
            refreshToken = data['refreshToken'] ?? data['refresh_token'];
          } else if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            // Response format: {data: {user: {...}}}
            final dataObj = data['data'] as Map<String, dynamic>;
            userData = dataObj['user'] as Map<String, dynamic>? ?? dataObj;
            accessToken = dataObj['accessToken'] ?? dataObj['access_token'] ?? dataObj['token'];
            refreshToken = dataObj['refreshToken'] ?? dataObj['refresh_token'];
          } else {
            // Assume the whole response is user data
            userData = data;
            accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
            refreshToken = data['refreshToken'] ?? data['refresh_token'];
          }
        } else {
          throw AppFailure(message: 'Invalid response format', code: 'LOGIN_ERROR');
        }

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
        if (userData is Map<String, dynamic>) {
          await LocalStorageHelper.setObject(AppConstants.userDataKey, userData);
        }

        // Return user
        return AuthUser.fromJson(userData);
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
        
        // Handle different response structures - check if it's a success response
        Map<String, dynamic> userData;
        String? accessToken;
        String? refreshToken;
        
        // Check if response has success flag
        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            // Response format: {success: true, message: "...", data: {...}}
            userData = data['data'] as Map<String, dynamic>? ?? data;
            accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
            refreshToken = data['refreshToken'] ?? data['refresh_token'];
          } else if (data.containsKey('user')) {
            // Response format: {user: {...}, accessToken: "..."}
            userData = data['user'] as Map<String, dynamic>;
            accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
            refreshToken = data['refreshToken'] ?? data['refresh_token'];
          } else if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            // Response format: {data: {user: {...}}}
            final dataObj = data['data'] as Map<String, dynamic>;
            userData = dataObj['user'] as Map<String, dynamic>? ?? dataObj;
            accessToken = dataObj['accessToken'] ?? dataObj['access_token'] ?? dataObj['token'];
            refreshToken = dataObj['refreshToken'] ?? dataObj['refresh_token'];
          } else {
            // Assume the whole response is user data
            userData = data;
            accessToken = data['accessToken'] ?? data['access_token'] ?? data['token'];
            refreshToken = data['refreshToken'] ?? data['refresh_token'];
          }
        } else {
          throw AppFailure(message: 'Invalid response format', code: 'REGISTER_ERROR');
        }

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
        if (userData is Map<String, dynamic>) {
          await LocalStorageHelper.setObject(AppConstants.userDataKey, userData);
        }

        // Return user
        return AuthUser.fromJson(userData);
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
        
        // Handle different response structures
        Map<String, dynamic> userData;
        
        if (data is Map<String, dynamic>) {
          if (data.containsKey('success') && data['success'] == true) {
            userData = data['data'] as Map<String, dynamic>? ?? data;
          } else if (data.containsKey('user')) {
            userData = data['user'] as Map<String, dynamic>;
          } else if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            final dataObj = data['data'] as Map<String, dynamic>;
            userData = dataObj['user'] as Map<String, dynamic>? ?? dataObj;
          } else {
            userData = data;
          }
        } else {
          return null;
        }
        
        return AuthUser.fromJson(userData);
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