import 'package:dio/dio.dart';
import 'package:pharmacy_app/core/network/dio_client.dart';

/// Repository for all Elaaj API endpoints
/// 
/// This class contains all API methods organized by category:
/// - Auth endpoints
/// - Identity endpoints
/// - Pharmacies endpoints
class ApiEndpoints {
  final Dio _dio = DioClient.instance.dio;

  // ========================= Auth Endpoints =========================

  /// POST /api/Auth/login
  /// Login with email and password
  Future<Map<String, dynamic>> authLogin({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/Auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/Auth/register
  /// Register a new account
  Future<Map<String, dynamic>> authRegister({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dio.post(
      '/api/Auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ========================= Identity Endpoints =========================

  /// POST /api/identity/register
  /// Register with email and password
  Future<Map<String, dynamic>> identityRegister({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/identity/register',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/identity/login
  /// Login with email, password and optional 2FA codes
  Future<Map<String, dynamic>> identityLogin({
    required String email,
    required String password,
    String? twoFactorCode,
    String? twoFactorRecoveryCode,
  }) async {
    final response = await _dio.post(
      '/api/identity/login',
      data: {
        'email': email,
        'password': password,
        if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        if (twoFactorRecoveryCode != null)
          'twoFactorRecoveryCode': twoFactorRecoveryCode,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/identity/refresh
  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _dio.post(
      '/api/identity/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/identity/confirmEmail
  /// Confirm email address
  Future<void> confirmEmail({
    required String userId,
    required String code,
    String? changedEmail,
  }) async {
    await _dio.get(
      '/api/identity/confirmEmail',
      queryParameters: {
        'userId': userId,
        'code': code,
        if (changedEmail != null) 'changedEmail': changedEmail,
      },
    );
  }

  /// POST /api/identity/resendConfirmationEmail
  /// Resend confirmation email
  Future<void> resendConfirmationEmail({required String email}) async {
    await _dio.post(
      '/api/identity/resendConfirmationEmail',
      data: {'email': email},
    );
  }

  /// POST /api/identity/forgotPassword
  /// Request password reset
  Future<void> forgotPassword({required String email}) async {
    await _dio.post(
      '/api/identity/forgotPassword',
      data: {'email': email},
    );
  }

  /// POST /api/identity/resetPassword
  /// Reset password with code
  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    await _dio.post(
      '/api/identity/resetPassword',
      data: {
        'email': email,
        'resetCode': resetCode,
        'newPassword': newPassword,
      },
    );
  }

  /// POST /api/identity/manage/2fa
  /// Manage two-factor authentication (requires auth token)
  Future<Map<String, dynamic>> manage2FA({
    bool? enable,
    String? twoFactorCode,
    bool? resetSharedKey,
    bool? resetRecoveryCodes,
    bool? forgetMachine,
  }) async {
    final response = await _dio.post(
      '/api/identity/manage/2fa',
      data: {
        if (enable != null) 'enable': enable,
        if (twoFactorCode != null) 'twoFactorCode': twoFactorCode,
        if (resetSharedKey != null) 'resetSharedKey': resetSharedKey,
        if (resetRecoveryCodes != null) 'resetRecoveryCodes': resetRecoveryCodes,
        if (forgetMachine != null) 'forgetMachine': forgetMachine,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/identity/manage/info
  /// Get account management info (requires auth token)
  Future<Map<String, dynamic>> getManageInfo() async {
    final response = await _dio.get(
      '/api/identity/manage/info',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/identity/manage/info
  /// Update account management info (requires auth token)
  Future<Map<String, dynamic>> updateManageInfo({
    String? newEmail,
    String? newPassword,
    String? oldPassword,
  }) async {
    final response = await _dio.post(
      '/api/identity/manage/info',
      data: {
        if (newEmail != null) 'newEmail': newEmail,
        if (newPassword != null) 'newPassword': newPassword,
        if (oldPassword != null) 'oldPassword': oldPassword,
      },
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/identity/profile
  /// Get user profile (requires auth token)
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/identity/profile');
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/identity/user
  /// Update user data (requires auth token)
  Future<void> updateUser({
    String? fullName,
    String? dateOfBirth,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _dio.patch(
      '/api/identity/user',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  /// POST /api/identity/userRole
  /// Add role to user (requires auth token)
  Future<void> addUserRole({
    required String userEmail,
    required String roleName,
  }) async {
    await _dio.post(
      '/api/identity/userRole',
      data: {
        'userEmail': userEmail,
        'roleName': roleName,
      },
    );
  }

  /// DELETE /api/identity/userRole
  /// Remove role from user (requires auth token)
  Future<void> deleteUserRole({
    required String userEmail,
    required String roleName,
  }) async {
    await _dio.delete(
      '/api/identity/userRole',
      data: {
        'userEmail': userEmail,
        'roleName': roleName,
      },
    );
  }

  // ========================= Pharmacies Endpoints =========================

  /// GET /api/Pharmacies
  /// Get list of all pharmacies
  Future<List<dynamic>> getPharmacies() async {
    final response = await _dio.get('/api/Pharmacies');
    return response.data as List;
  }

  /// POST /api/Pharmacies
  /// Create a new pharmacy (requires auth token)
  /// Body: CreatePharmacyCommand
  Future<Map<String, dynamic>> createPharmacy({
    String? name,
    String? imageUrl,
    required String address,
    String? workingHours,
    bool hasDelivery = false,
    String? contactNumber,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.post(
      '/api/Pharmacies',
      data: {
        if (name != null) 'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'address': address,
        if (workingHours != null) 'workingHours': workingHours,
        'hasDelivery': hasDelivery,
        if (contactNumber != null) 'contactNumber': contactNumber,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/Pharmacies/{id}
  /// Get pharmacy by ID (ID must be a valid GUID)
  Future<Map<String, dynamic>> getPharmacyById({required String id}) async {
    final response = await _dio.get('/api/Pharmacies/$id');
    return response.data as Map<String, dynamic>;
  }

  /// PUT /api/Pharmacies/{id}
  /// Update an existing pharmacy (requires auth token)
  /// Body: UpdatePharmacyCommand (same fields as CreatePharmacyCommand)
  Future<Map<String, dynamic>> updatePharmacy({
    required String id,
    String? name,
    String? imageUrl,
    String? address,
    String? workingHours,
    bool? hasDelivery,
    String? contactNumber,
    double? latitude,
    double? longitude,
  }) async {
    final response = await _dio.put(
      '/api/Pharmacies/$id',
      data: {
        if (name != null) 'name': name,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (address != null) 'address': address,
        if (workingHours != null) 'workingHours': workingHours,
        if (hasDelivery != null) 'hasDelivery': hasDelivery,
        if (contactNumber != null) 'contactNumber': contactNumber,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/Pharmacies/{id}
  /// Delete a pharmacy (requires auth token)
  Future<void> deletePharmacy({required String id}) async {
    await _dio.delete('/api/Pharmacies/$id');
  }

  /// GET /api/Pharmacies/nearby
  /// Get pharmacies near a location
  /// Query params: lat (double), lon (double), radius (double, default: 5)
  Future<List<dynamic>> getNearbyPharmacies({
    required double lat,
    required double lon,
    double radius = 5.0,
  }) async {
    final response = await _dio.get(
      '/api/Pharmacies/nearby',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'radius': radius,
      },
    );
    return response.data as List;
  }

  /// POST /api/Pharmacies/toggle-favorite
  /// Toggle pharmacy favorite status (requires auth token)
  /// Body: ToggleFavoriteCommand
  Future<Map<String, dynamic>> toggleFavorite({
    required String pharmacyId,
  }) async {
    final response = await _dio.post(
      '/api/Pharmacies/toggle-favorite',
      data: {
        'pharmacyId': pharmacyId,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
