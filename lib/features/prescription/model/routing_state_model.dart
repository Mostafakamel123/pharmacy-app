import 'package:pharmacy_app/features/prescription/model/pharmacy_model.dart';
import 'package:pharmacy_app/features/prescription/model/prescription_model.dart';

/// Enum for prescription request status
enum RoutingStatus {
  initial,
  searching,
  contactingPharmacy,
  waitingForResponse,
  pharmacyResponded,
  allPharmaciesFailed,
  completed,
  error,
}

/// Enum for pharmacy response status
enum PharmacyResponseStatus {
  pending,
  accepted,
  rejected,
  timeout,
  noResponse,
}

/// Complete routing state model
class RoutingStateModel {
  final String id;
  final String patientId;
  final PrescriptionModel prescription;
  final RoutingStatus status;
  final List<PharmacyModel> nearbyPharmacies;
  final int currentPharmacyIndex;
  final PharmacyModel? currentPharmacy;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final DateTime? lockTime; // When pharmacy responded
  final int remainingTime; // seconds remaining for current pharmacy
  final String? chatId; // When pharmacy responds, lock to chat
  final String? lockPharmacyId; // Which pharmacy has locked the request
  final List<String> failedPharmacyIds; // Pharmacies that didn't respond
  final String? errorMessage;
  final bool? isRequestPending; // Tracks if a request is pending (default: false)

  RoutingStateModel({
    required this.id,
    required this.patientId,
    required this.prescription,
    required this.status,
    required this.nearbyPharmacies,
    this.currentPharmacyIndex = 0,
    this.currentPharmacy,
    required this.createdAt,
    this.lastUpdatedAt,
    this.lockTime,
    this.remainingTime = 300, // 5 minutes default
    this.chatId,
    this.lockPharmacyId,
    this.failedPharmacyIds = const [],
    this.errorMessage,
    this.isRequestPending = false, // Default to false
  });

  /// Get the next pharmacy in queue
  PharmacyModel? getNextPharmacy() {
    if (currentPharmacyIndex + 1 < nearbyPharmacies.length) {
      return nearbyPharmacies[currentPharmacyIndex + 1];
    }
    return null;
  }

  /// Check if all pharmacies have been tried
  bool allPharmaciesTried() {
    return currentPharmacyIndex >= nearbyPharmacies.length - 1;
  }

  /// Mark pharmacy as failed and move to next
  RoutingStateModel markPharmacyAsFailed(String pharmacyId) {
    final updatedFailedIds = [...failedPharmacyIds, pharmacyId];
    return copyWith(
      failedPharmacyIds: updatedFailedIds,
      currentPharmacyIndex: currentPharmacyIndex + 1,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Lock request to a pharmacy when it responds
  RoutingStateModel lockToPharmacy(String pharmacyId, String chatId) {
    return copyWith(
      status: RoutingStatus.pharmacyResponded,
      lockPharmacyId: pharmacyId,
      chatId: chatId,
      lockTime: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
  }

  RoutingStateModel copyWith({
    String? id,
    String? patientId,
    PrescriptionModel? prescription,
    RoutingStatus? status,
    List<PharmacyModel>? nearbyPharmacies,
    int? currentPharmacyIndex,
    PharmacyModel? currentPharmacy,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    DateTime? lockTime,
    int? remainingTime,
    String? chatId,
    String? lockPharmacyId,
    List<String>? failedPharmacyIds,
    String? errorMessage,
    bool? isRequestPending,
  }) {
    return RoutingStateModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      prescription: prescription ?? this.prescription,
      status: status ?? this.status,
      nearbyPharmacies: nearbyPharmacies ?? this.nearbyPharmacies,
      currentPharmacyIndex: currentPharmacyIndex ?? this.currentPharmacyIndex,
      currentPharmacy: currentPharmacy ?? this.currentPharmacy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lockTime: lockTime ?? this.lockTime,
      remainingTime: remainingTime ?? this.remainingTime,
      chatId: chatId ?? this.chatId,
      lockPharmacyId: lockPharmacyId ?? this.lockPharmacyId,
      failedPharmacyIds: failedPharmacyIds ?? this.failedPharmacyIds,
      errorMessage: errorMessage ?? this.errorMessage,
      isRequestPending: isRequestPending ?? this.isRequestPending,
    );
  }

  @override
  String toString() =>
      'RoutingStateModel(id: $id, status: $status, currentPharmacy: ${currentPharmacy?.name})';
}
