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
  Future<void> register(String fullName, String email, String password, String confirmPassword);
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String email, String resetCode, String newPassword);
  Future<void> resendConfirmationEmail(String email);
  Future<void> confirmEmail(String userId, String code, {String? changedEmail});
  Future<Map<String, dynamic>?> getProfileInfo();
  Future<void> updateAccountInfo({String? newEmail, String? newPassword, String? oldPassword});
  Future<void> updateUserDetails({String? fullName, String? dateOfBirth, String? imageUrl, double? latitude, double? longitude});
  Future<Map<String, dynamic>?> getProfile();
  Future<Map<String, dynamic>> refreshToken(String refreshTokenValue);
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
          'twoFactorCode': null,
          'twoFactorRecoveryCode': null,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Extract tokens from response
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final expiresIn = data['expiresIn'] as int? ?? 3600;
        
        if (accessToken == null) {
          throw AppFailure(message: 'No access token received', code: 'LOGIN_ERROR');
        }

        // Save tokens with expiry time
        await LocalStorageHelper.setString(
          AppConstants.authTokenKey,
          accessToken,
        );
        if (refreshToken != null) {
          await LocalStorageHelper.setString(
            AppConstants.refreshTokenKey,
            refreshToken,
          );
        }
        // Calculate and save expiry time
        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch;
        await LocalStorageHelper.setString(
          AppConstants.tokenExpiryKey,
          expiresAt.toString(),
        );

        // Get user info from profile endpoint
        final profileData = await getProfileInfo();
        if (profileData != null) {
          await LocalStorageHelper.setObject(AppConstants.userDataKey, profileData);
          return AuthUser.fromJson(profileData);
        }
        
        return null;
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
  Future<void> register(String fullName, String email, String password, String confirmPassword) async {
    try {
      // Validate passwords match before sending
      if (password != confirmPassword) {
        throw ValidationFailure(
          message: 'Passwords do not match',
          errors: {'confirmPassword': ['Passwords do not match']},
        );
      }

      final response = await _dio.post(
        '/api/Auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        // Success - empty response body
        return;
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
  Future<void> confirmEmail(String userId, String code, {String? changedEmail}) async {
    try {
      final response = await _dio.get(
        '/api/identity/confirmEmail',
        queryParameters: {
          'userId': userId,
          'code': code,
          if (changedEmail != null) 'changedEmail': changedEmail,
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
  Future<Map<String, dynamic>?> getProfileInfo() async {
    try {
      final response = await _dio.get(
        '/api/identity/manage/info',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateAccountInfo({String? newEmail, String? newPassword, String? oldPassword}) async {
    try {
      final response = await _dio.post(
        '/api/identity/manage/info',
        data: {
          if (newEmail != null) 'newEmail': newEmail,
          if (newPassword != null) 'newPassword': newPassword,
          if (oldPassword != null) 'oldPassword': oldPassword,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'UPDATE_ACCOUNT_ERROR');
    }
  }

  @override
  Future<void> updateUserDetails({String? fullName, String? dateOfBirth, String? imageUrl, double? latitude, double? longitude}) async {
    try {
      final response = await _dio.patch(
        '/api/identity/user',
        data: {
          if (fullName != null) 'fullName': fullName,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'UPDATE_USER_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get(
        '/api/identity/profile',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshTokenValue) async {
    try {
      final response = await _dio.post(
        '/api/identity/refresh',
        data: {'refreshToken': refreshTokenValue},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'REFRESH_TOKEN_ERROR');
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
    
    // Handle validation errors from Elaaj API
    if (statusCode == 400 && data.containsKey('errors')) {
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null) {
        final validationErrors = <String, List<String>>{};
        errors.forEach((key, value) {
          if (value is List) {
            validationErrors[key] = value.cast<String>();
          } else if (value is String) {
            validationErrors[key] = [value];
          }
        });
        return ValidationFailure(
          message: message,
          errors: validationErrors,
        );
      }
    }
  }

  if (statusCode == 401) {
    return AuthFailure(
      message: message,
      tokenInvalid: true,
    );
  } else if (statusCode >= 400 && statusCode < 500) {
    return ValidationFailure(
      message: message,
      errors: null,
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