/// Enum for medicine availability status
enum AvailabilityStatus {
  available,
  notAvailable,
  partialAvailable,
  pending,
}

/// Medicine availability response from pharmacy
class MedicineAvailabilityModel {
  final String medicineId;
  final String medicineName;
  final AvailabilityStatus status;
  final int? quantity;
  final double? price;
  final String? notes;
  final DateTime? timestamp;

  MedicineAvailabilityModel({
    required this.medicineId,
    required this.medicineName,
    required this.status,
    this.quantity,
    this.price,
    this.notes,
    this.timestamp,
  });

  String get statusEmoji {
    switch (status) {
      case AvailabilityStatus.available:
        return '✅ Available';
      case AvailabilityStatus.notAvailable:
        return '❌ Not Available';
      case AvailabilityStatus.partialAvailable:
        return '⚠️ Partial Available';
      case AvailabilityStatus.pending:
        return '⏳ Checking...';
    }
  }

  MedicineAvailabilityModel copyWith({
    String? medicineId,
    String? medicineName,
    AvailabilityStatus? status,
    int? quantity,
    double? price,
    String? notes,
    DateTime? timestamp,
  }) {
    return MedicineAvailabilityModel(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() =>
      'MedicineAvailabilityModel(medicineName: $medicineName, status: $status, price: $price)';
}
