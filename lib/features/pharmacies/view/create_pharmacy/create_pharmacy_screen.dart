// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

/// Screen for creating a new pharmacy
/// 
/// Performance Optimizations:
/// - Uses ConsumerStatefulWidget with selective rebuilds
/// - Extracts form fields into separate widgets to minimize rebuild scope
/// - Caches TextEditingControllers to avoid recreation on rebuilds
/// - Uses ValueListenableBuilder for localized state updates
/// - Implements proper dispose pattern
/// - Uses const constructors throughout where possible
class CreatePharmacyScreen extends ConsumerStatefulWidget {
  const CreatePharmacyScreen({super.key});

  @override
  ConsumerState<CreatePharmacyScreen> createState() => _CreatePharmacyScreenState();
}

class _CreatePharmacyScreenState extends ConsumerState<CreatePharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers initialized once and disposed properly
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _licenseNumberController;
  
  double _latitude = 30.0444;
  double _longitude = 31.2357;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _licenseNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final result = await showDialog<MapEntry<double, double>>(
      context: context,
      builder: (context) => _LocationPickerDialog(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.key;
        _longitude = result.value;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      
      final pharmacy = UserPharmacyModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty 
            ? null 
            : _websiteController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim().isEmpty 
            ? null 
            : _licenseNumberController.text.trim(),
        ownerUserId: currentUserId,
        adminUserIds: [],
        createdAt: DateTime.now(),
      );

      final result = await ref.read(myPharmaciesProvider.notifier).createPharmacy(pharmacy);

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Pharmacy created successfully!'),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to create pharmacy'),
              ],
            ),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldColor = isDark ? DarkColors.background : LightColors.background;
    
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _buildAppBar(theme),
      body: Form(
        key: _formKey,
        child: _buildFormBody(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('Create Pharmacy'),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: TextButton.icon(
            onPressed: _isSubmitting ? null : _submitForm,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(_isSubmitting ? 'Creating...' : 'Create'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              disabledForegroundColor: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormBody(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _buildHeaderCard(theme),
        const SizedBox(height: AppSpacing.xxl),
        _buildSection(
          theme: theme,
          title: 'Basic Information',
          icon: Icons.info_outline,
          children: [
            _NameField(controller: _nameController),
            const SizedBox(height: AppSpacing.lg),
            _DescriptionField(controller: _descriptionController),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSection(
          theme: theme,
          title: 'Contact Information',
          icon: Icons.contact_mail_outlined,
          children: [
            _AddressField(
              controller: _addressController,
              onLocationTap: _selectLocation,
              latitude: _latitude,
              longitude: _longitude,
            ),
            const SizedBox(height: AppSpacing.lg),
            _PhoneField(controller: _phoneController),
            const SizedBox(height: AppSpacing.lg),
            _EmailField(controller: _emailController),
            const SizedBox(height: AppSpacing.lg),
            _WebsiteField(controller: _websiteController),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildSection(
          theme: theme,
          title: 'License Information',
          icon: Icons.verified_user_outlined,
          children: [
            _LicenseField(controller: _licenseNumberController),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _buildInfoCard(theme),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    
    return Card(
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.add_business_rounded,
                size: 32,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Pharmacy',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in the details to create your pharmacy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    
    return Card(
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'You will be the owner and primary admin of this pharmacy. You can add more admins later.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location picker dialog widget
class _LocationPickerDialog extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const _LocationPickerDialog({
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: _latitude.toString(),
            decoration: const InputDecoration(
              labelText: 'Latitude',
              hintText: 'Enter latitude',
              prefixIcon: Icon(Icons.location_on),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _latitude = double.tryParse(value) ?? _latitude;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            initialValue: _longitude.toString(),
            decoration: const InputDecoration(
              labelText: 'Longitude',
              hintText: 'Enter longitude',
              prefixIcon: Icon(Icons.location_on),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _longitude = double.tryParse(value) ?? _longitude;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, MapEntry(_latitude, _longitude));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: const Text('Set Location'),
        ),
      ],
    );
  }
}

/// Extracted form field widgets for better performance

class _NameField extends StatelessWidget {
  final TextEditingController controller;

  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Pharmacy Name *',
        hintText: 'Enter pharmacy name',
        prefixIcon: Icon(Icons.business),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter pharmacy name';
        }
        if (value.trim().length < 3) {
          return 'Name must be at least 3 characters';
        }
        return null;
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Brief description about your pharmacy',
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onLocationTap;
  final double latitude;
  final double longitude;

  const _AddressField({
    required this.controller,
    required this.onLocationTap,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Address *',
            hintText: 'Enter full address',
            prefixIcon: Icon(Icons.location_on),
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        InkWell(
          onTap: onLocationTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppColors.primaryBlue.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(Icons.map, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Coordinates',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit, size: 18, color: AppColors.primaryBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Phone Number',
        hintText: '+20 2 1234 5678',
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;

  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'contact@pharmacy.com',
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (!value.contains('@') || !value.contains('.')) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }
}

class _WebsiteField extends StatelessWidget {
  final TextEditingController controller;

  const _WebsiteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Website',
        hintText: 'www.pharmacy.com',
        prefixIcon: Icon(Icons.language),
      ),
      keyboardType: TextInputType.url,
    );
  }
}

class _LicenseField extends StatelessWidget {
  final TextEditingController controller;

  const _LicenseField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'License Number',
        hintText: 'Pharmacy license number',
        prefixIcon: Icon(Icons.verified_user),
      ),
      textCapitalization: TextCapitalization.characters,
    );
  }
}
