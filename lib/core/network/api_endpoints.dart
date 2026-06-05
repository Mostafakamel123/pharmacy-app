import 'dart:convert';
import 'package:Elaaj/core/network/dio_client.dart';
import 'package:dio/dio.dart';

/// Repository for all Elaaj API endpoints
/// 
/// This class contains all API methods organized by category:
/// - Auth endpoints
/// - Identity endpoints
/// - Pharmacies endpoints
class ApiEndpoints {
  final Dio _dio = DioClient.instance.dio;

  Map<String, dynamic> _safeParseMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      if (data.trim().isEmpty) return {};
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      } catch (e) {
        print('DEBUG ApiEndpoints: Error parsing map response: $e');
      }
    }
    return {};
  }

  List<dynamic> _safeParseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is String) {
      if (data.trim().isEmpty) return [];
      try {
        final parsed = jsonDecode(data);
        if (parsed is List) return parsed;
      } catch (e) {
        print('DEBUG ApiEndpoints: Error parsing list response: $e');
      }
    }
    return [];
  }

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
    return _safeParseMap(response.data);
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
    return _safeParseMap(response.data);
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
    return _safeParseMap(response.data);
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
    return _safeParseMap(response.data);
  }

  /// POST /api/Auth/refresh-token
  /// Refresh access token using refresh token
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
    String? expiredToken,
  }) async {
    final response = await _dio.post(
      '/api/Auth/refresh-token',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {
        'Accept': 'application/json',
        if (expiredToken != null) 'Authorization': 'Bearer $expiredToken',
      }),
    );
    return _safeParseMap(response.data);
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
    return _safeParseMap(response.data);
  }

  /// GET /api/identity/manage/info
  /// Get account management info (requires auth token)
  Future<Map<String, dynamic>> getManageInfo() async {
    final response = await _dio.get(
      '/api/identity/manage/info',
      options: Options(headers: {'Accept': 'application/json'}),
    );
    return _safeParseMap(response.data);
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
    return _safeParseMap(response.data);
  }

  /// GET /api/identity/profile
  /// Get user profile (requires auth token)
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/api/identity/profile');
    return _safeParseMap(response.data);
  }

  /// PUT /api/identity/profile
  /// Update user profile (requires auth token)
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String dateOfBirth,
    String? imagePath,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final formDataMap = {
      'FullName': fullName,
      'DateOfBirth': dateOfBirth,
      'Address': address,
      'Latitude': latitude.toString(),
      'Longitude': longitude.toString(),
    };

    final formData = FormData.fromMap(formDataMap);

    if (imagePath != null &&
        imagePath.isNotEmpty &&
        !imagePath.startsWith('http') &&
        !imagePath.startsWith('/images')) {
      formData.files.add(MapEntry(
        'ImageFile',
        await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      ));
    }

    final response = await _dio.put(
      '/api/identity/profile',
      data: formData,
    );
    return _safeParseMap(response.data);
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

  // ========================= Pharmacy Admins Endpoints =========================

  /// POST /api/PharmacyAdmins/assign
  /// Assign a user as pharmacy admin (requires auth token)
  Future<Map<String, dynamic>> assignPharmacyAdmin({
    required String userId,
    required String pharmacyId,
  }) async {
    final response = await _dio.post(
      '/api/PharmacyAdmins/assign',
      data: {
        'userId': userId,
        'pharmacyId': pharmacyId,
      },
    );
    return _safeParseMap(response.data);
  }

  /// GET /api/PharmacyAdmins/{pharmacyId}
  /// Get list of admins for a pharmacy (requires auth token)
  Future<List<dynamic>> getPharmacyAdmins(String pharmacyId) async {
    final response = await _dio.get('/api/PharmacyAdmins/$pharmacyId');
    return _safeParseList(response.data);
  }

  /// DELETE /api/PharmacyAdmins/{pharmacyId}/{userId}
  /// Remove an admin from a pharmacy (requires auth token)
  Future<Map<String, dynamic>> deletePharmacyAdmin(String pharmacyId, String userId) async {
    final response = await _dio.delete('/api/PharmacyAdmins/$pharmacyId/$userId');
    return _safeParseMap(response.data);
  }

  /// GET /api/Pharmacies
  /// Get list of all pharmacies
  Future<List<dynamic>> getPharmacies() async {
    final response = await _dio.get('/api/Pharmacies');
    return _safeParseList(response.data);
  }

  /// GET /api/Pharmacies/my-pharmacies
  /// Get current user's pharmacies (requires auth token)
  Future<List<dynamic>> getMyPharmacies() async {
    final response = await _dio.get('/api/Pharmacies/my-pharmacies');
    return _safeParseList(response.data);
  }

  /// POST /api/Pharmacies
  /// Create a new pharmacy (requires auth token)
  /// Body: CreatePharmacyCommand
  Future<Map<String, dynamic>> createPharmacy({
    String? name,
    String? imagePath,
    required String address,
    String? workingHours,
    bool hasDelivery = false,
    String? contactNumber,
    required double latitude,
    required double longitude,
  }) async {
    final formDataMap = {
      if (name != null) 'Name': name,
      'Address': address,
      if (workingHours != null) 'WorkingHours': workingHours,
      'HasDelivery': hasDelivery.toString(),
      if (contactNumber != null) 'ContactNumber': contactNumber,
      'Latitude': latitude.toString(),
      'Longitude': longitude.toString(),
    };

    final formData = FormData.fromMap(formDataMap);

    if (imagePath != null && imagePath.isNotEmpty) {
      formData.files.add(MapEntry(
        'ImageUrl',
        await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      ));
    }

    final response = await _dio.post(
      '/api/Pharmacies',
      data: formData,
    );
    return _safeParseMap(response.data);
  }

  /// GET /api/Pharmacies/{id}
  /// Get pharmacy by ID (ID must be a valid GUID)
  Future<Map<String, dynamic>> getPharmacyById({required String id}) async {
    final response = await _dio.get('/api/Pharmacies/$id');
    return _safeParseMap(response.data);
  }

  /// PUT /api/Pharmacies/{id}
  /// Update an existing pharmacy (requires auth token)
  /// Body: UpdatePharmacyCommand (same fields as CreatePharmacyCommand)
  Future<Map<String, dynamic>> updatePharmacy({
    required String id,
    String? name,
    String? imagePath,
    String? address,
    String? workingHours,
    bool? hasDelivery,
    String? contactNumber,
    double? latitude,
    double? longitude,
  }) async {
    final formDataMap = {
      if (name != null) 'Name': name,
      if (address != null) 'Address': address,
      if (workingHours != null) 'WorkingHours': workingHours,
      if (hasDelivery != null) 'HasDelivery': hasDelivery.toString(),
      if (contactNumber != null) 'ContactNumber': contactNumber,
      if (latitude != null) 'Latitude': latitude.toString(),
      if (longitude != null) 'Longitude': longitude.toString(),
    };

    final formData = FormData.fromMap(formDataMap);

    if (imagePath != null && imagePath.isNotEmpty && !imagePath.startsWith('http') && !imagePath.startsWith('/images')) {
      formData.files.add(MapEntry(
        'ImageUrl',
        await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        ),
      ));
    }

    final response = await _dio.put(
      '/api/Pharmacies/$id',
      data: formData,
    );
    return _safeParseMap(response.data);
  }

  /// DELETE /api/Pharmacies/{id}
  /// Delete a pharmacy (requires auth token)
  Future<Map<String, dynamic>> deletePharmacy({required String id}) async {
    try {
      final response = await _dio.delete('/api/Pharmacies/$id');
      return _safeParseMap(response.data) ?? {'message': 'Pharmacy deleted successfully'};
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final responseBody = e.response?.data;
      
      print('DEBUG ApiEndpoints: Error deleting pharmacy $id');
      print('  Status Code: $statusCode');
      print('  Response Body: $responseBody');
      print('  Error Message: ${e.message}');
      
      String errorMsg = 'Failed to delete pharmacy';
      if (responseBody is Map && responseBody.containsKey('message')) {
        errorMsg = responseBody['message'] as String;
      } else if (statusCode == 403) {
        errorMsg = 'Permission denied - Only the owner can delete this pharmacy';
      } else if (statusCode == 404) {
        errorMsg = 'Pharmacy not found';
      } else if (statusCode == 401) {
        errorMsg = 'Unauthorized - Please log in again';
      } else {
        errorMsg = 'Error: ${e.message}';
      }
      throw Exception(errorMsg);
    } catch (e) {
      print('DEBUG ApiEndpoints: Unexpected error deleting pharmacy $id: $e');
      rethrow;
    }
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
    return _safeParseList(response.data);
  }

  /// GET /api/Pharmacies/search
  /// Search pharmacies by keyword (name or address).
  /// Returns the `items` array from the paginated response wrapper.
  Future<List<dynamic>> searchPharmacies({
    required String keyword,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/api/Pharmacies/search',
      queryParameters: {
        'keyword': keyword,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );
    // Response is a paginated wrapper: { items: [...], totalCount, ... }
    final data = _safeParseMap(response.data);
    if (data.containsKey('items')) {
      return data['items'] as List;
    }
    // Fallback: plain list (defensive)
    return _safeParseList(response.data);
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
    return _safeParseMap(response.data);
  }

  // ========================= Posts Endpoints =========================

  /// GET /api/Posts
  /// Get paginated list of posts
  /// Query params: pageNumber (int32, default: 1), pageSize (int32, default: 10)
  Future<List<dynamic>> getPosts({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/api/Posts',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );
    // The API might return a pagination wrapper or direct list
    // Handle both cases
    final data = _safeParseMap(response.data);
    if (data.containsKey('items')) {
      return data['items'] as List;
    }
    final listData = _safeParseList(response.data);
    if (listData.isNotEmpty) {
      return listData;
    }
    return [];
  }

  /// POST /api/Posts
  /// Create a new post (requires auth token)
  /// multipart/form-data: Content (string, max 1000), File (binary?)
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? filePath,
  }) async {
    FormData formData;
    
    if (filePath != null && filePath.isNotEmpty) {
      // With file upload
      formData = FormData.fromMap({
        'Content': content,
        'File': await MultipartFile.fromFile(filePath),
      });
    } else {
      // Without file
      formData = FormData.fromMap({
        'Content': content,
      });
    }

    final response = await _dio.post(
      '/api/Posts',
      data: formData,
    );
    return _safeParseMap(response.data);
  }

  /// GET /api/Posts/my-posts
  /// Get current user's posts
  /// Query params: pageNumber (int32, default: 1), pageSize (int32, default: 10)
  Future<List<dynamic>> getMyPosts({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/api/Posts/my-posts',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );
    final data = _safeParseMap(response.data);
    if (data.containsKey('items')) {
      return data['items'] as List;
    }
    final listData = _safeParseList(response.data);
    if (listData.isNotEmpty) {
      return listData;
    }
    return [];
  }

  /// PUT /api/Posts/{postId}
  /// Update an existing post (requires auth token)
  /// multipart/form-data: Content (string), File (binary?)
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required String content,
    String? filePath,
  }) async {
    FormData formData;
    
    if (filePath != null && filePath.isNotEmpty && !filePath.startsWith('http') && !filePath.startsWith('/images')) {
      // With file upload
      formData = FormData.fromMap({
        'Content': content,
        'File': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
    } else {
      // Without file
      formData = FormData.fromMap({
        'Content': content,
      });
    }

    final response = await _dio.put(
      '/api/Posts/$postId',
      data: formData,
    );
    return _safeParseMap(response.data);
  }

  /// DELETE /api/Posts/{postId}
  /// Delete an existing post (requires auth token)
  /// Only the post owner can delete their own post
  /// Returns empty response on success (204 No Content or 200 OK with empty body)
  Future<Map<String, dynamic>> deletePost({
    required String postId,
  }) async {
    try {
      final response = await _dio.delete(
        '/api/Posts/$postId',
      );
      // Handle both empty responses and JSON responses
      return _safeParseMap(response.data) ?? {'message': 'Post deleted successfully'};
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final responseBody = e.response?.data;
      
      print('DEBUG ApiEndpoints: Error deleting post $postId');
      print('  Status Code: $statusCode');
      print('  Response Body: $responseBody');
      print('  Error Message: ${e.message}');
      
      // Create a descriptive error message
      String errorMsg = 'Failed to delete post';
      if (statusCode == 500) {
        errorMsg = 'Server error (500) - Backend failed to delete post. Please check if post exists and you are the owner.';
      } else if (statusCode == 403) {
        errorMsg = 'Permission denied - You can only delete your own posts';
      } else if (statusCode == 404) {
        errorMsg = 'Post not found - It may have already been deleted';
      } else if (statusCode == 401) {
        errorMsg = 'Unauthorized - Please log in again';
      } else {
        errorMsg = 'Error: ${e.message}';
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      print('DEBUG ApiEndpoints: Unexpected error deleting post $postId: $e');
      rethrow;
    }
  }

  /// POST /api/PostReplies
  /// Submit a pharmacy reply to a community post (requires auth token)
  /// Only users with Pharmacy role can call this endpoint
  Future<Map<String, dynamic>> replyToPost({
    required int postId,
    required String replyContent,
    required String receiverId,
    required String pharmacyId,
  }) async {
    final response = await _dio.post(
      '/api/PostReplies',
      data: {
        'postId': postId,
        'replyContent': replyContent,
        'receiverId': receiverId,
        'pharmacyId': pharmacyId,
      },
    );
    return _safeParseMap(response.data);
  }


  // ========================= Prescriptions Endpoints =========================

  /// POST /api/Prescriptions
  /// Upload a prescription (requires auth token)
  /// multipart/form-data: File (binary), Notes (string?), Latitude (double), Longitude (double)
  Future<Map<String, dynamic>> uploadPrescription({
    required String filePath,
    String? notes,
    required double latitude,
    required double longitude,
  }) async {
    final formData = FormData.fromMap({
      'File': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
      if (notes != null && notes.isNotEmpty) 'Notes': notes,
      'Latitude': latitude,
      'Longitude': longitude,
    });

    final response = await _dio.post(
      '/api/Prescriptions',
      data: formData,
    );
    return _safeParseMap(response.data);
  }

  /// GET /api/Prescriptions/{id}
  /// Get a specific prescription by ID (including replies)
  Future<Map<String, dynamic>> getPrescriptionById({required String id}) async {
    final response = await _dio.get('/api/Prescriptions/$id');
    return _safeParseMap(response.data);
  }

  /// GET /api/Prescriptions/my-prescriptions
  /// Get current user's prescriptions with pagination
  Future<List<dynamic>> getMyPrescriptions({
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/api/Prescriptions/my-prescriptions',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );
    final data = _safeParseMap(response.data);
    if (data.containsKey('items')) {
      return data['items'] as List;
    }
    final listData = _safeParseList(response.data);
    if (listData.isNotEmpty) {
      return listData;
    }
    return [];
  }

  /// PATCH /api/Prescriptions/{id}/status
  /// Update prescription status (requires auth token)
  /// Body: PrescriptionStatus (Enum int32: 0,1,2,3,4,5)
  Future<void> updatePrescriptionStatus({
    required String id,
    required int status,
  }) async {
    final response = await _dio.patch(
      '/api/Prescriptions/$id/status',
      data: status,
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Failed to update status: ${response.data}',
      );
    }
  }

  /// PUT /api/Prescriptions/{prescriptionId}/replies/{replyId}/accept
  /// Accept a specific pharmacy reply/offer for a prescription
  Future<void> acceptPharmacyReply({
    required String prescriptionId,
    required String replyId,
  }) async {
    await _dio.put(
      '/api/Prescriptions/$prescriptionId/replies/$replyId/accept',
    );
  }

  /// GET /api/Prescriptions/nearby/{pharmacyId}
  /// Get active prescriptions near a specific pharmacy
  Future<List<dynamic>> getNearbyPrescriptions({
    required String pharmacyId,
    double radius = 5.0,
  }) async {
    final response = await _dio.get(
      '/api/Prescriptions/nearby/$pharmacyId',
      queryParameters: {
        'radius': radius.toInt(),
      },
    );
    return _safeParseList(response.data);
  }

  /// POST /api/Prescriptions/{id}/replies
  /// Submit a pharmacy reply/offer to a prescription request
  Future<Map<String, dynamic>> replyToPrescription({
    required String prescriptionId,
    required String pharmacyId,
    required String message,
    required double totalPrice,
    required bool isAvailable,
  }) async {
    final response = await _dio.post(
      '/api/Prescriptions/$prescriptionId/replies',
      data: {
        'prescriptionId': prescriptionId,
        'pharmacyId': pharmacyId,
        'message': message,
        'totalPrice': totalPrice,
        'isAvailable': isAvailable,
      },
    );
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Failed to submit offer: ${response.data}',
      );
    }
    return _safeParseMap(response.data);
  }

  /// PUT /api/Prescriptions/{id}
  /// Update prescription text/notes
  Future<Map<String, dynamic>> updatePrescription({
    required String id,
    required String notes,
  }) async {
    final response = await _dio.put(
      '/api/Prescriptions/$id',
      data: '"$notes"',
      options: Options(
        contentType: 'application/json',
      ),
    );
    return _safeParseMap(response.data);
  }

  /// DELETE /api/Prescriptions/{id}
  /// Cancel or delete a prescription request
  Future<void> deletePrescription({
    required String id,
  }) async {
    await _dio.delete(
      '/api/Prescriptions/$id',
    );
  }
}
