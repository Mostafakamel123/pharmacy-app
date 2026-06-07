// ignore_for_file: avoid_print

import 'dart:io';
import 'package:Elaaj/core/network/dio_client.dart';
import 'package:Elaaj/features/chat/model/chat_message.dart';
import 'package:dio/dio.dart';

/// Repository that wraps all /api/Chat REST endpoints.
///
/// All error messages are extracted from [e.response?.data?['message']]
/// following the existing project convention.
class ChatRepository {
  final Dio _dio = DioClient.instance.dio;

  // ── Send Message ────────────────────────────────────────────────────────────

  /// POST /api/Chat/send
  ///
  /// [prescriptionId] – GUID of the prescription.
  /// [senderId]       – current user's ID (patient or pharmacy).
  /// [receiverId]     – the other party's ID.
  /// [content]        – message text.
  ///
  /// Returns the server-persisted [ChatMessage].
  Future<ChatMessage> sendMessage({
    required String prescriptionId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/api/Chat/send',
        data: {
          'prescriptionId': prescriptionId,
          'senderId': senderId,
          'receiverId': receiverId,
          'content': content,
        },
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        final msg = _extractErrorMessage(response.data) ??
            'Failed to send message (${response.statusCode})';
        throw Exception(msg);
      }

      final data = response.data;
      if (data is Map) {
        return ChatMessage.fromJson(data);
      }
      throw Exception('Unexpected response format from /api/Chat/send');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e.response?.data) ??
          e.message ??
          'Network error while sending message';
      print('DEBUG ChatRepository.sendMessage: $msg');
      throw Exception(msg);
    }
  }

  // ── Get Chat History ─────────────────────────────────────────────────────────

  /// GET /api/Chat/history/{prescriptionId}/{otherUserId}
  ///
  /// [prescriptionId] – GUID of the prescription.
  /// [otherUserId]    – the OTHER party's ID (not the current user).
  /// [pharmacyId]     – pass this ONLY when the caller is a PHARMACY;
  ///                    omit (leave null) when called by a PATIENT.
  ///
  /// Returns an ordered list of [ChatMessage] objects.
  Future<List<ChatMessage>> getChatHistory({
    required String prescriptionId,
    required String otherUserId,
    String? pharmacyId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (pharmacyId != null && pharmacyId.isNotEmpty) {
        queryParams['pharmacyId'] = pharmacyId;
      }

      final url = '/api/Chat/history/$prescriptionId/$otherUserId';
      
      // Log details of the request

      final response = await _dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode != null && response.statusCode! >= 400) {
        final msg = _extractErrorMessage(response.data) ??
            'Failed to load chat history (${response.statusCode})';
        throw Exception(msg);
      }

      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => ChatMessage.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e.response?.data) ??
          e.message ??
          'Network error while loading chat history';
      
      // Write debug details to file in workspace
      try {
        final file = dLinkFile();
        file.writeAsStringSync(
          '=== GET CHAT HISTORY ERROR ===\n'
          'Timestamp: ${DateTime.now()}\n'
          'PrescriptionId: "$prescriptionId"\n'
          'OtherUserId: "$otherUserId"\n'
          'PharmacyId (query): "$pharmacyId"\n'
          'URL: /api/Chat/history/$prescriptionId/$otherUserId\n'
          'Status Code: ${e.response?.statusCode}\n'
          'Response Data: ${e.response?.data}\n'
          'Error Message: $msg\n'
          'DioException Type: ${e.type}\n'
          '==============================\n',
          mode: FileMode.writeOnlyAppend,
        );
      } catch (err) {
        print('DEBUG ChatRepository: Failed to write to chat_debug.txt: $err');
      }
      
      print('DEBUG ChatRepository.getChatHistory: $msg');
      throw Exception(msg);
    } catch (e) {
      final msg = e.toString();
      try {
        final file = dLinkFile();
        file.writeAsStringSync(
          '=== GET CHAT HISTORY UNEXPECTED ERROR ===\n'
          'Timestamp: ${DateTime.now()}\n'
          'PrescriptionId: "$prescriptionId"\n'
          'OtherUserId: "$otherUserId"\n'
          'PharmacyId (query): "$pharmacyId"\n'
          'Error: $msg\n'
          '==============================\n',
          mode: FileMode.writeOnlyAppend,
        );
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static File dLinkFile() {
    return File('d:/pharmacy_app/chat_debug.txt');
  }

  // ── Private Helpers ──────────────────────────────────────────────────────────

  /// Extracts the 'message' field from a response body, case-insensitively.
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      for (final entry in data.entries) {
        if (entry.key.toString().toLowerCase() == 'message') {
          return entry.value?.toString();
        }
      }
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
