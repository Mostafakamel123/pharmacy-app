import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/helpers/local_storage_helper.dart';
import 'package:pharmacy_app/core/network/api_endpoints.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_dashboard_controller.dart';

/// Local State class for Pharmacy Prescriptions
class PharmacyPrescriptionsLocalState {
  final Set<String> rejectedIds;
  final Map<String, Map<String, dynamic>> offeredDetails;

  const PharmacyPrescriptionsLocalState({
    required this.rejectedIds,
    required this.offeredDetails,
  });

  PharmacyPrescriptionsLocalState copyWith({
    Set<String>? rejectedIds,
    Map<String, Map<String, dynamic>>? offeredDetails,
  }) {
    return PharmacyPrescriptionsLocalState(
      rejectedIds: rejectedIds ?? this.rejectedIds,
      offeredDetails: offeredDetails ?? this.offeredDetails,
    );
  }
}

/// StateNotifier to manage and persist pharmacy prescription replies & rejections
class PharmacyPrescriptionsLocalNotifier extends StateNotifier<PharmacyPrescriptionsLocalState> {
  final String pharmacyId;

  PharmacyPrescriptionsLocalNotifier(this.pharmacyId)
      : super(const PharmacyPrescriptionsLocalState(rejectedIds: {}, offeredDetails: {})) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    try {
      final rejectedList = LocalStorageHelper.getStringListSync('pharmacy_${pharmacyId}_rejected_prescriptions') ?? [];
      
      Map<String, Map<String, dynamic>> offeredMap = {};
      final offeredJson = LocalStorageHelper.getStringSync('pharmacy_${pharmacyId}_offered_prescriptions');
      if (offeredJson != null) {
        final decoded = jsonDecode(offeredJson) as Map<String, dynamic>;
        offeredMap = decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
      }

      state = PharmacyPrescriptionsLocalState(
        rejectedIds: rejectedList.toSet(),
        offeredDetails: offeredMap,
      );
    } catch (e) {
      print('DEBUG: Error loading pharmacy local state: $e');
    }
  }

  /// Mark a prescription as locally rejected/hidden
  Future<void> rejectPrescription(String prescriptionId) async {
    final newRejected = Set<String>.from(state.rejectedIds)..add(prescriptionId);
    state = state.copyWith(rejectedIds: newRejected);
    await LocalStorageHelper.setStringList(
      'pharmacy_${pharmacyId}_rejected_prescriptions',
      newRejected.toList(),
    );
  }

  /// Store detailed reply offer locally
  Future<void> offerPrescription({
    required String prescriptionId,
    required double price,
    required String message,
    required bool isAvailable,
  }) async {
    final newOffered = Map<String, Map<String, dynamic>>.from(state.offeredDetails);
    newOffered[prescriptionId] = {
      'price': price,
      'message': message,
      'isAvailable': isAvailable,
      'submittedAt': DateTime.now().toIso8601String(),
    };
    state = state.copyWith(offeredDetails: newOffered);
    await LocalStorageHelper.setString(
      'pharmacy_${pharmacyId}_offered_prescriptions',
      jsonEncode(newOffered),
    );
  }
}

/// Provider family for pharmacy's locally persisted prescription status
final pharmacyPrescriptionsLocalProvider = StateNotifierProvider.family<
    PharmacyPrescriptionsLocalNotifier, PharmacyPrescriptionsLocalState, String>((ref, pharmacyId) {
  return PharmacyPrescriptionsLocalNotifier(pharmacyId);
});

/// Family provider to poll active prescriptions near a specific pharmacy
final nearbyPrescriptionsProvider = FutureProvider.family<List<dynamic>, ({String pharmacyId, double radius})>((ref, params) async {
  final apiEndpoints = ApiEndpoints();
  try {
    return await apiEndpoints.getNearbyPrescriptions(
      pharmacyId: params.pharmacyId,
      radius: params.radius,
    );
  } catch (e) {
    print('DEBUG: Error getting prescriptions near pharmacy ${params.pharmacyId}: $e');
    return [];
  }
});

/// Provider for pharmacy-side API actions
final pharmacyActionsProvider = Provider((ref) => PharmacyActions(ref));

class PharmacyActions {
  final Ref ref;
  final ApiEndpoints _apiEndpoints = ApiEndpoints();

  PharmacyActions(this.ref);

  /// Submit a price and availability offer to a prescription request
  Future<bool> submitReply({
    required String prescriptionId,
    required String pharmacyId,
    required String message,
    required double totalPrice,
    required bool isAvailable,
  }) async {
    try {
      await _apiEndpoints.replyToPrescription(
        prescriptionId: prescriptionId,
        pharmacyId: pharmacyId,
        message: message,
        totalPrice: totalPrice,
        isAvailable: isAvailable,
      );

      // Save locally as offered to filter out of Pending and track offer details
      await ref.read(pharmacyPrescriptionsLocalProvider(pharmacyId).notifier).offerPrescription(
        prescriptionId: prescriptionId,
        price: totalPrice,
        message: message,
        isAvailable: isAvailable,
      );

      // Invalidate dashboard and nearby request streams to load fresh data
      ref.invalidate(pharmacyDashboardProvider);
      ref.invalidate(nearbyPrescriptionsProvider);
      return true;
    } catch (e) {
      print('DEBUG: Error submitting pharmacy reply: $e');
      return false;
    }
  }

  /// Change the status of a prescription request (e.g. preparing, delivered)
  Future<bool> changeStatus({
    required String prescriptionId,
    required int status,
  }) async {
    try {
      await _apiEndpoints.updatePrescriptionStatus(
        id: prescriptionId,
        status: status,
      );
      ref.invalidate(pharmacyDashboardProvider);
      ref.invalidate(nearbyPrescriptionsProvider);
      return true;
    } catch (e) {
      print('DEBUG: Error updating prescription status: $e');
      return false;
    }
  }
}
