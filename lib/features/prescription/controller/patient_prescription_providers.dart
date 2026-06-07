// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/features/prescription/controller/prescription_providers.dart';
import 'package:Elaaj/features/prescription/model/prescription.dart';

/// Provider to list all patient's prescriptions (typed using Prescription model)
final myPrescriptionsProvider = FutureProvider<List<Prescription>>((ref) async {
  final apiEndpoints = ApiEndpoints();
  try {
    final list = await apiEndpoints.getMyPrescriptions(pageNumber: 1, pageSize: 100);
    return list.map((item) => Prescription.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  } catch (e) {
    print('DEBUG: Error getting myPrescriptions: $e');
    return [];
  }
});

/// Provider to list all patient's prescriptions
final patientPrescriptionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiEndpoints = ApiEndpoints();
  try {
    return await apiEndpoints.getMyPrescriptions(pageNumber: 1, pageSize: 100);
  } catch (e) {
    print('DEBUG: Error getting patient prescriptions: $e');
    return [];
  }
});

/// Provider to get a single prescription by ID (including all pharmacy replies)
final singlePrescriptionProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final apiEndpoints = ApiEndpoints();
  try {
    return await apiEndpoints.getPrescriptionById(id: id);
  } catch (e) {
    print('DEBUG: Error getting single prescription $id: $e');
    return {};
  }
});

/// Notifier provider to perform patient-side actions on a prescription
final patientActionsProvider = Provider((ref) => PatientActions(ref));

class PatientActions {
  final Ref ref;
  final ApiEndpoints _apiEndpoints = ApiEndpoints();

  PatientActions(this.ref);

  /// Accept a specific reply/offer from a pharmacy
  Future<bool> acceptOffer({
    required String prescriptionId,
    required String replyId,
  }) async {
    try {
      await _apiEndpoints.acceptPharmacyReply(
        prescriptionId: prescriptionId,
        replyId: replyId,
      );
      // Refresh list to show updated status
      ref.invalidate(patientPrescriptionsProvider);
      return true;
    } catch (e) {
      print('DEBUG: Error accepting pharmacy offer: $e');
      return false;
    }
  }

  /// Cancel/delete a prescription request
  Future<bool> cancelRequest({
    required String prescriptionId,
  }) async {
    try {
      await _apiEndpoints.deletePrescription(id: prescriptionId);
      
      // If the current search flow matches this prescription, reset it
      final currentRouting = ref.read(routingStateNotifierProvider);
      if (currentRouting != null && currentRouting.id == prescriptionId) {
        ref.read(routingStateNotifierProvider.notifier).resetRouting();
      }

      // Refresh list to show updated status
      ref.invalidate(patientPrescriptionsProvider);
      return true;
    } catch (e) {
      print('DEBUG: Error canceling prescription request: $e');
      return false;
    }
  }

  /// Modify notes/details on a prescription request
  Future<bool> modifyRequest({
    required String prescriptionId,
    required String newNotes,
  }) async {
    try {
      await _apiEndpoints.updatePrescription(id: prescriptionId, notes: newNotes);
      ref.invalidate(patientPrescriptionsProvider);
      return true;
    } catch (e) {
      print('DEBUG: Error modifying prescription request: $e');
      return false;
    }
  }
}
