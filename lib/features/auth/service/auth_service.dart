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
      // Use /api/identity/login endpoint as per Elaaj API spec
      // This endpoint returns AccessTokenResponse with accessToken, refreshToken, expiresIn
      final response = await _dio.post(
        '/api/identity/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Extract tokens from AccessTokenResponse
        final accessToken = data['accessToken'] as String?;
        final refreshToken = data['refreshToken'] as String?;
        final expiresIn = data['expiresIn'] as int? ?? 3600;
        
        if (accessToken == null || accessToken.isEmpty) {
          throw AppFailure(message: 'No access token received', code: 'LOGIN_ERROR');
        }

        // Save tokens with expiry time
        await LocalStorageHelper.setString(
          AppConstants.authTokenKey,
          accessToken,
        );
        if (refreshToken != null && refreshToken.isNotEmpty) {
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

        // Get user info from profile endpoint after successful login
        final profileData = await getProfile();
        if (profileData != null) {
          await LocalStorageHelper.setObject(AppConstants.userDataKey, profileData);
          return AuthUser.fromJson(profileData);
        }
        
        // Fallback: create minimal user object from login context
        final user = AuthUser(
          email: email,
          emailVerified: false, // Will be verified later via manage/info
        );
        return user;
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

      // Use /api/identity/register endpoint as per Elaaj API spec
      // RegisterRequest requires: email, password
      final response = await _dio.post(
        '/api/identity/register',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        // Success - registration complete, user should verify email
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
      // Note: Elaaj API doesn't have a dedicated logout endpoint in /api/identity
      // Logout is handled client-side by clearing tokens
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
      // Use /api/identity/forgotPassword POST endpoint
      // ForgotPasswordRequest: { email: string (required) }
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
      // Use /api/identity/resetPassword POST endpoint
      // ResetPasswordRequest: { email: string, resetCode: string, newPassword: string }
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
      // Use /api/identity/resendConfirmationEmail POST endpoint
      // ResendConfirmationEmailRequest: { email: string (required) }\n      final response = await _dio.post(
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
      // Use /api/identity/confirmEmail GET endpoint
      // Query params: userId (required), code (required), changedEmail (optional)
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
      // Use /api/identity/manage/info GET endpoint to get email and isEmailConfirmed
      // Returns InfoResponse: { email: string, isEmailConfirmed: bool }
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
      // Use /api/identity/manage/info POST endpoint to update email/password
      // InfoRequest: { newEmail?, newPassword?, oldPassword? }
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
      // Use /api/identity/user PATCH endpoint to update user details
      // UpdateUserDetailsCommand: { fullName?, dateOfBirth?, imageUrl?, latitude?, longitude? }
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
      // Use /api/identity/profile endpoint to get user profile details
      // This returns comprehensive user information
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