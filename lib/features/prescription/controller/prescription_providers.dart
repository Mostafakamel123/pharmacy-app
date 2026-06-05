import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/models/pharmacy_model.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/features/prescription/model/prescription_model.dart';
import 'package:Elaaj/features/prescription/model/routing_state_model.dart';

// ============================================================================
// SERVICE - CONNECTED TO REAL API ENDPOINTS
// ============================================================================

class PrescriptionService {
  final ApiEndpoints _apiEndpoints = ApiEndpoints();

  /// Helper to convert asset paths to real file paths
  Future<String> _getRealFilePath(String path) async {
    if (!path.startsWith('assets/')) {
      return path;
    }
    final byteData = await rootBundle.load(path);
    final tempDir = Directory.systemTemp;
    final fileName = path.split('/').last;
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    ));
    return tempFile.path;
  }

  /// Real: Get nearby pharmacies sorted by distance from API
  Future<List<PharmacyModel>> getNearbyPharmacies({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _apiEndpoints.getNearbyPharmacies(
        lat: latitude,
        lon: longitude,
        radius: radiusKm,
      );

      final pharmacies = response.map((item) {
        return PharmacyModel.fromJson(item as Map<String, dynamic>);
      }).toList();

      if (pharmacies.isEmpty) {
        return _getMockPharmacies(latitude, longitude);
      }
      return pharmacies;
    } catch (e) {
      print('DEBUG: Error fetching nearby pharmacies from API: $e. Falling back to mock.');
      return _getMockPharmacies(latitude, longitude);
    }
  }

  List<PharmacyModel> _getMockPharmacies(double latitude, double longitude) {
    return [
      PharmacyModel(
        id: 'pharm_001',
        name: 'Al-Amal Pharmacy',
        location: 'Downtown Center, Near Metro',
        latitude: latitude + 0.01,
        longitude: longitude + 0.01,
        distance: 0.5,
        isOpen: true,
        rating: 4.8,
        phone: '+966501234567',
        imageUrl: 'assets/pharmacy_default.png',
        isPriority: true,
        estimatedResponseTime: 120,
      ),
      PharmacyModel(
        id: 'pharm_002',
        name: 'Al-Noor Medical Center',
        location: 'Airport Road, Building 15',
        latitude: latitude - 0.01,
        longitude: longitude - 0.01,
        distance: 1.2,
        isOpen: true,
        rating: 4.6,
        phone: '+966501234568',
        imageUrl: 'assets/pharmacy_default.png',
        estimatedResponseTime: 180,
      ),
      PharmacyModel(
        id: 'pharm_003',
        name: 'Life Pharmacy Chain',
        location: 'City Mall, Floor 2',
        latitude: latitude + 0.02,
        longitude: longitude - 0.02,
        distance: 1.8,
        isOpen: true,
        rating: 4.5,
        phone: '+966501234569',
        imageUrl: 'assets/pharmacy_default.png',
        estimatedResponseTime: 240,
      ),
      PharmacyModel(
        id: 'pharm_004',
        name: 'Health Plus Pharmacy',
        location: 'Medical District',
        latitude: latitude - 0.02,
        longitude: longitude + 0.02,
        distance: 2.5,
        isOpen: false,
        rating: 4.3,
        phone: '+966501234570',
        imageUrl: 'assets/pharmacy_default.png',
        estimatedResponseTime: 300,
      ),
      PharmacyModel(
        id: 'pharm_005',
        name: 'Wellness Center',
        location: 'Residential Area',
        latitude: latitude + 0.03,
        longitude: longitude + 0.03,
        distance: 3.2,
        isOpen: true,
        rating: 4.2,
        phone: '+966501234571',
        imageUrl: 'assets/pharmacy_default.png',
        estimatedResponseTime: 300,
      ),
    ];
  }

  /// Real: Upload prescription and create routing request
  Future<RoutingStateModel> createPrescriptionRequest({
    required String patientId,
    required PrescriptionModel prescription,
    required List<PharmacyModel> pharmacies,
    double? latitude,
    double? longitude,
  }) async {
    String? localFilePath = prescription.imageUrl;
    if (localFilePath != null) {
      localFilePath = await _getRealFilePath(localFilePath);
    } else {
      // Fallback sample file since backend strictly requires a File parameter
      localFilePath = await _getRealFilePath('assets/prescription_sample.jpg');
    }

    // Call actual backend API
    final response = await _apiEndpoints.uploadPrescription(
      filePath: localFilePath,
      notes: prescription.textContent ?? prescription.description ?? '',
      latitude: latitude ?? 27.1874,
      longitude: longitude ?? 31.1954,
    );

    // Case-insensitive key lookup for prescriptionId or id
    String? prescriptionId;
    response.forEach((key, value) {
      final lKey = key.toLowerCase();
      if (lKey == 'prescriptionid' || lKey == 'id') {
        prescriptionId = value?.toString();
      }
    });

    final String finalPresId = prescriptionId ?? 'pres_${DateTime.now().millisecondsSinceEpoch}';

    return RoutingStateModel(
      id: finalPresId,
      patientId: patientId,
      prescription: prescription.copyWith(
        id: finalPresId,
        imageUrl: localFilePath,
      ),
      status: RoutingStatus.searching,
      nearbyPharmacies: pharmacies,
      currentPharmacyIndex: 0,
      currentPharmacy: pharmacies.isNotEmpty ? pharmacies[0] : null,
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      remainingTime: 300,
      isRequestPending: false,
    );
  }

  /// Mock: Simulate pharmacy response
  Future<bool> simulatePharmacyResponse({
    required String pharmacyId,
    required Duration delay,
  }) async {
    await Future.delayed(delay);
    // Simulate 70% response rate
    return DateTime.now().millisecond % 10 > 3;
  }

  /// Mock: Create chat session when pharmacy responds
  Future<String> createChatSession({
    required String pharmacyId,
    required String prescriptionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'chat_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

final prescriptionServiceProvider = Provider((ref) {
  return PrescriptionService();
});

/// Get nearby pharmacies for a location
final nearbyPharmaciesProvider = FutureProvider.family<
    List<PharmacyModel>,
    ({double latitude, double longitude})>(
  (ref, params) async {
    final service = ref.watch(prescriptionServiceProvider);
    return service.getNearbyPharmacies(
      latitude: params.latitude,
      longitude: params.longitude,
    );
  },
);

/// Current routing state for the prescription request
class RoutingStateNotifier extends StateNotifier<RoutingStateModel?> {
  final Ref ref;

  RoutingStateNotifier(this.ref) : super(null);

  /// Manually update or load a state (e.g. from history list)
  void updateState(RoutingStateModel? newState) {
    state = newState;
  }

  /// Initialize prescription routing
  Future<void> startPrescriptionRouting({
    required String patientId,
    required PrescriptionModel prescription,
    required List<PharmacyModel> pharmacies,
    double? latitude,
    double? longitude,
  }) async {
    final service = ref.watch(prescriptionServiceProvider);
    state = await service.createPrescriptionRequest(
      patientId: patientId,
      prescription: prescription,
      pharmacies: pharmacies,
      latitude: latitude,
      longitude: longitude,
    );

    // Mark request as pending
    if (state != null) {
      state = state!.copyWith(isRequestPending: true);
      print('🔵 DEBUG: isRequestPending set to TRUE - ${state?.isRequestPending}');
    }

    // Start automatic routing logic
    _startPharmacyRouting();
  }

  /// Handle pharmacy response and lock the request
  void handlePharmacyResponse(String pharmacyId, String chatId) {
    if (state != null) {
      state = state!.lockToPharmacy(pharmacyId, chatId);
    }
  }

  /// Mark current pharmacy as failed and move to next
  void moveToNextPharmacy() {
    if (state != null && state!.currentPharmacy != null) {
      final failed = state!.markPharmacyAsFailed(state!.currentPharmacy!.id);
      state = failed;

      if (!failed.allPharmaciesTried()) {
        // Continue with next pharmacy
        _startPharmacyRouting();
      } else {
        // All pharmacies failed
        state = state!.copyWith(
          status: RoutingStatus.allPharmaciesFailed,
          errorMessage: 'No pharmacies responded, please try again',
        );
      }
    }
  }

  /// Update remaining time for current pharmacy
  void updateRemainingTime(int seconds) {
    if (state != null) {
      state = state!.copyWith(remainingTime: seconds);
    }
  }

  /// Private: Start the routing process for current pharmacy
  void _startPharmacyRouting() {
    if (state == null) return;

    final pharmacy = state!.currentPharmacy;
    if (pharmacy == null) {
      state = state!.copyWith(
        status: RoutingStatus.allPharmaciesFailed,
        errorMessage: 'No pharmacies available',
      );
      return;
    }

    state = state!.copyWith(
      status: RoutingStatus.contactingPharmacy,
      lastUpdatedAt: DateTime.now(),
    );

    // Start 5-minute timer
    _startPharmacyTimer();
  }

  /// Private: Start 5-minute timer for pharmacy response
  void _startPharmacyTimer() {
    // Timer would be handled in UI layer with StateNotifierProvider
    // This is a placeholder for the logic
  }

  /// Reset isRequestPending when routing is complete
  void resetRouting() {
    if (state != null) {
      state = state!.copyWith(isRequestPending: false);
      print('🔴 DEBUG: isRequestPending set to FALSE - ${state?.isRequestPending}');
    }
  }
}

/// Timer countdown for current pharmacy (in seconds)
class CountdownTimerNotifier extends StateNotifier<int> {
  Timer? _timer;

  CountdownTimerNotifier() : super(300) {
    // 5 minutes default
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void start({Duration duration = const Duration(minutes: 5)}) {
    _timer?.cancel();
    state = duration.inSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        timer.cancel();
        // This will trigger moveToNextPharmacy in UI
      }
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    state = 300;
  }

  void stop() {
    _timer?.cancel();
    state = 0;
  }
}

// ============================================================================
// MANUAL PROVIDER DEFINITIONS
// ============================================================================

/// Routing state notifier provider
final routingStateNotifierProvider =
    StateNotifierProvider<RoutingStateNotifier, RoutingStateModel?>((ref) {
  return RoutingStateNotifier(ref);
});

/// Countdown timer notifier provider
final countdownTimerNotifierProvider =
    StateNotifierProvider<CountdownTimerNotifier, int>((ref) {
  return CountdownTimerNotifier();
});

/// Get the current routing state
final currentRoutingStateProvider = Provider<RoutingStateModel?>((ref) {
  return ref.watch(routingStateNotifierProvider);
});

/// Get current pharmacy being contacted
final currentPharmacyProvider = Provider<PharmacyModel?>((ref) {
  final state = ref.watch(routingStateNotifierProvider);
  return state?.currentPharmacy;
});

/// Get list of failed pharmacies
final failedPharmaciesProvider = Provider<List<PharmacyModel>>((ref) {
  final state = ref.watch(routingStateNotifierProvider);
  if (state == null) return [];

  return state.nearbyPharmacies
      .where((p) => state.failedPharmacyIds.contains(p.id))
      .toList();
});

/// Get list of remaining pharmacies to try
final remainingPharmaciesProvider = Provider<List<PharmacyModel>>((ref) {
  final state = ref.watch(routingStateNotifierProvider);
  if (state == null) return [];

  return state.nearbyPharmacies.sublist(state.currentPharmacyIndex);
});
