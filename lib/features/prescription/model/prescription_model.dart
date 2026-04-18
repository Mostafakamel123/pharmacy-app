/// Prescription model representing a medical prescription
class PrescriptionModel {
  final String id;
  final String patientId;
  final String? imageUrl;
  final String? textContent;
  final String? description;
  final DateTime createdAt;
  final bool isImage;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    this.imageUrl,
    this.textContent,
    this.description,
    required this.createdAt,
    required this.isImage,
  });

  PrescriptionModel copyWith({
    String? id,
    String? patientId,
    String? imageUrl,
    String? textContent,
    String? description,
    DateTime? createdAt,
    bool? isImage,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      imageUrl: imageUrl ?? this.imageUrl,
      textContent: textContent ?? this.textContent,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isImage: isImage ?? this.isImage,
    );
  }

  @override
  String toString() =>
      'PrescriptionModel(id: $id, isImage: $isImage, createdAt: $createdAt)';
}
