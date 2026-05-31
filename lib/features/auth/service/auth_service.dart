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
  Future<void> verifyEmail(String email, String code);
  Future<void> confirmEmail(String userId, String code, {String? changedEmail});
  Future<Map<String, dynamic>?> getProfileInfo();
  Future<void> updateAccountInfo({String? newEmail, String? newPassword, String? oldPassword});
  Future<void> updateUserDetails({String? fullName, String? dateOfBirth, String? imageUrl, double? latitude, double? longitude});
  Future<Map<String, dynamic>?> getProfile();
  Future<Map<String, dynamic>> refreshToken(String refreshTokenValue);
  
  // User Role Management
  Future<void> assignUserRole({required String userEmail, required String roleName});
  Future<void> removeUserRole({required String userEmail, required String roleName});
  
  // Pharmacy Admin Management
  Future<Map<String, dynamic>> assignPharmacyAdmin({required String userId, required String pharmacyId});
  
  // User Search
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int pageNumber = 1,
    int pageSize = 10,
  });
}

/// Implementation of Auth Service using Dio - Elaaj API
class AuthServiceImpl implements AuthService {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<AuthUser?> login(String email, String password) async {
    try {
      // Use /api/Auth/login endpoint as per Elaaj API spec
      // LoginDto requires: email (required), password (required)
      final response = await _dio.post(
        '/api/Auth/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>?;
        
        // Extract tokens - the API may return them in different formats
        String? accessToken;
        String? refreshToken;
        int expiresIn = 3600;
        
        if (data != null) {
          accessToken = data['accessToken'] as String? ?? data['token'] as String? ?? data['access_token'] as String?;
          refreshToken = data['refreshToken'] as String? ?? data['refresh_token'] as String?;
          expiresIn = data['expiresIn'] as int? ?? data['expires_in'] as int? ?? 3600;
        }
        
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

      // Use /api/Auth/register endpoint as per Elaaj API spec
      // RegisterUserCommand requires: fullName, email, password, confirmPassword
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
      // Use /api/Auth/verify-email POST endpoint to resend verification email
      // VerifyEmailCommand: { email: string, code: string }
      // For resending, we just send the email
      final response = await _dio.post(
        '/api/Auth/verify-email',
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
  Future<void> verifyEmail(String email, String code) async {
    try {
      // Use /api/Auth/verify-email POST endpoint for OTP verification
      // VerifyEmailCommand: { email: string, code: string }
      final response = await _dio.post(
        '/api/Auth/verify-email',
        data: {
          'email': email,
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

  @override
  Future<void> assignUserRole({required String userEmail, required String roleName}) async {
    try {
      // Use /api/identity/userRole POST endpoint to assign a role to a user
      // AssignUserRoleCommand: { userEmail: string, roleName: string }
      final response = await _dio.post(
        '/api/identity/userRole',
        data: {
          'userEmail': userEmail,
          'roleName': roleName,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'ASSIGN_ROLE_ERROR');
    }
  }

  @override
  Future<void> removeUserRole({required String userEmail, required String roleName}) async {
    try {
      // Use /api/identity/userRole DELETE endpoint to remove a role from a user
      // UnAssignUserRoleCommand: { userEmail: string, roleName: string }
      final response = await _dio.delete(
        '/api/identity/userRole',
        data: {
          'userEmail': userEmail,
          'roleName': roleName,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _failureFromResponse(response);
      }
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'REMOVE_ROLE_ERROR');
    }
  }

  @override
  Future<Map<String, dynamic>> assignPharmacyAdmin({required String userId, required String pharmacyId}) async {
    try {
      // Use /api/PharmacyAdmins/assign POST endpoint to assign a user as pharmacy admin
      // AssignPharmacyAdminCommand: { userId: string, pharmacyId: uuid }
      final response = await _dio.post(
        '/api/PharmacyAdmins/assign',
        data: {
          'userId': userId,
          'pharmacyId': pharmacyId,
        },
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
      throw AppFailure(message: e.toString(), code: 'ASSIGN_PHARMACY_ADMIN_ERROR');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/Users/search',
        queryParameters: {
          'Search': query,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          final items = data['items'] as List;
          return items.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [];
    } on Failure catch (e) {
      rethrow;
    } catch (e) {
      throw AppFailure(message: e.toString(), code: 'SEARCH_USERS_ERROR');
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