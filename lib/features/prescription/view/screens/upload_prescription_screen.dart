// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';
import 'package:pharmacy_app/features/prescription/model/prescription_model.dart';
import 'package:pharmacy_app/core/models/pharmacy_model.dart';
import 'package:pharmacy_app/features/prescription/controller/prescription_providers.dart';

/// Upload Prescription Screen
/// Allows patient to upload prescription image or enter text
class UploadPrescriptionScreen extends ConsumerStatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  ConsumerState<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState
    extends ConsumerState<UploadPrescriptionScreen> {
  late TextEditingController _descriptionController;
  String? _selectedImagePath;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSendRequest() async {
    final isRequestPending =
        ref.read(routingStateNotifierProvider)?.isRequestPending ?? false;
    print(
      '🚀 DEBUG UploadScreen: Checking if pending... isRequestPending=$isRequestPending',
    );
    if (isRequestPending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There is already a pending request. Please wait.'),
        ),
      );
      return;
    }

    if (_selectedImagePath == null && _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload image or add description')),
      );
      return;
    }

    try {
      // Create prescription model
      final prescription = PrescriptionModel(
        id: 'pres_${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'patient_123', // Get from auth
        imageUrl: _selectedImagePath,
        textContent: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        createdAt: DateTime.now(),
        isImage: _isImage && _selectedImagePath != null,
      );

      // Fetch nearby pharmacies using read() instead of watch()
      final List<PharmacyModel> pharmacies = await ref.read(
        nearbyPharmaciesProvider(
          (latitude: 24.7136, longitude: 46.6753), // Mock location
        ).future,
      );

      // Start routing
      if (mounted) {
        await ref
            .read(routingStateNotifierProvider.notifier)
            .startPrescriptionRouting(
              patientId: 'patient_123',
              prescription: prescription,
              pharmacies: pharmacies,
            );

        // Defer navigation to next frame using post-frame callback
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.replace(AppRoutes.searchingPharmacies);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Prescription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '📤 Upload Your Prescription',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose to upload an image or describe your prescription',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LightColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Upload Image Section
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // Divider
              const Divider(),
              const SizedBox(height: 24),

              // Text Description Section
              _buildDescriptionSection(),
              const SizedBox(height: 32),

              // Send Button
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Image (Optional)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryBlue, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: const Color(0xFF0EA5E9).withOpacity(0.05),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Click to upload prescription',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Camera • Gallery',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LightColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedImagePath != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: LightColors.surfaceVariant,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Center(
                            child: _selectedImagePath!.startsWith('assets/')
                                ? Image.asset(
                                    _selectedImagePath!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 150,
                                  )
                                : Image.file(
                                    File(_selectedImagePath!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 150,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImagePath = null;
                                _isImage = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.accentRed,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          // TODO: Implement camera
                          setState(() {
                            _selectedImagePath =
                                'assets/prescription_sample.jpg';
                            _isImage = true;
                          });
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          // TODO: Implement gallery
                          setState(() {
                            _selectedImagePath =
                                'assets/prescription_sample.jpg';
                            _isImage = true;
                          });
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Details (Optional)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText:
                'Describe your prescription or any special notes...\n\nExample:\n- Medicine name and dosage\n- Duration\n- Any allergies',
            hintMaxLines: 6,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: LightColors.divider,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleSendRequest,
        icon: const Icon(Icons.send_rounded),
        label: const Text('Send Request'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.primaryBlue,
        ),
      ),
    );
  }
}
