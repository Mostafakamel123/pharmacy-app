// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

/// Screen for creating a new pharmacy
class CreatePharmacyScreen extends ConsumerStatefulWidget {
  const CreatePharmacyScreen({super.key});

  @override
  ConsumerState<CreatePharmacyScreen> createState() => _CreatePharmacyScreenState();
}

class _CreatePharmacyScreenState extends ConsumerState<CreatePharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _workingHoursController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  
  double _latitude = 27.189; // Default coordinate (dairut)
  double _longitude = 31.1954;
  bool _isSubmitting = false;
  bool _hasDelivery = false;

  // GPS Location Status
  bool _gpsLoading = false;
  String _gpsStatus = 'Pending'; // 'Pending', 'Success', 'Error'
  String _gpsError = '';

  // Image Picker
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _workingHoursController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();

    // Automatically fetch GPS Location on screen start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGPSLocation();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workingHoursController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchGPSLocation() async {
    if (!mounted) return;
    setState(() {
      _gpsLoading = true;
      _gpsStatus = 'Pending';
      _gpsError = '';
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gpsStatus = 'Error';
            _gpsError = 'Location services are disabled.';
            _gpsLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _gpsStatus = 'Error';
              _gpsError = 'Location permission was denied.';
              _gpsLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gpsStatus = 'Error';
            _gpsError = 'Location permissions are permanently denied.';
            _gpsLoading = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _gpsStatus = 'Success';
          _gpsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gpsStatus = 'Error';
          _gpsError = 'Failed to fetch GPS coordinates: $e';
          _gpsLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pharmacy image logo'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUserId = ref.read(currentUserIdProvider);
      
      final pharmacy = UserPharmacyModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: null,
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        phone: _phoneController.text.trim(),
        workingHours: _workingHoursController.text.trim(),
        hasDelivery: _hasDelivery,
        email: null,
        website: null,
        licenseNumber: null,
        ownerUserId: currentUserId,
        adminUserIds: [],
        createdAt: DateTime.now(),
        logoUrl: _selectedImagePath,
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
      appBar: AppBar(
        title: const Text('New Pharmacy'),
        elevation: 0,
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
                disabledForegroundColor: AppColors.primaryCyan,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildHeaderCard(theme),
            const SizedBox(height: AppSpacing.xxl),
            _buildImagePickerSection(theme),
            const SizedBox(height: AppSpacing.xxl),
            _buildFormFields(theme),
            const SizedBox(height: AppSpacing.xxl),
            _buildGPSStatusWidget(theme),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    
    return Card(
      color: AppColors.primaryBlue.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
                    'Create Pharmacy',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your pharmacy details to get started',
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

  Widget _buildImagePickerSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.black12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pharmacy Logo *',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceBottomSheet(theme),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: _selectedImagePath != null ? AppColors.primaryBlue : borderColor,
                      width: 2,
                      style: _selectedImagePath != null ? BorderStyle.solid : BorderStyle.solid,
                    ),
                    boxShadow: _selectedImagePath != null
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                    child: _selectedImagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImagePath = null;
                                    });
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentRed,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_rounded,
                                size: 36,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Image',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_selectedImagePath == null)
                Text(
                  'Select a beautiful picture of your storefront or logo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImageSourceBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    theme: theme,
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceButton(
                    theme: theme,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pharmacy Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Pharmacy Name *',
            hintText: 'Enter pharmacy name',
            prefixIcon: Icon(Icons.business_rounded),
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
        ),
        const SizedBox(height: AppSpacing.lg),

        // Contact Number
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Contact Number *',
            hintText: 'e.g. 01273476754',
            prefixIcon: Icon(Icons.phone_rounded),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter contact number';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Address
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address *',
            hintText: 'Enter pharmacy street address',
            prefixIcon: Icon(Icons.location_on_rounded),
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

        // Working Hours
        TextFormField(
          controller: _workingHoursController,
          decoration: const InputDecoration(
            labelText: 'Working Hours *',
            hintText: 'e.g. 12-12 or 24 Hours',
            prefixIcon: Icon(Icons.access_time_filled_rounded),
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter working hours';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Delivery Service Switch
        SwitchListTile(
          title: const Text('Has Delivery Service'),
          subtitle: Text(_hasDelivery ? 'Offers home delivery' : 'No home delivery'),
          value: _hasDelivery,
          onChanged: (value) {
            setState(() {
              _hasDelivery = value;
            });
          },
          secondary: Icon(
            _hasDelivery ? Icons.local_shipping_rounded : Icons.shopping_bag_rounded,
            color: _hasDelivery ? AppColors.primaryGreen : null,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildGPSStatusWidget(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    if (_gpsLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Fetching automatic location coordinates from GPS...',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    if (_gpsStatus == 'Success') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_fixed_rounded, color: AppColors.primaryGreen, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GPS Location Active',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lat: ${_latitude.toStringAsFixed(6)}, Lng: ${_longitude.toStringAsFixed(6)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryGreen),
              onPressed: _fetchGPSLocation,
              tooltip: 'Refresh Location',
            ),
          ],
        ),
      );
    }

    // Error or disabled GPS
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_off_rounded, color: AppColors.accentRed, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS Location Access Failed',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_gpsError.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _gpsError,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accentRed),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _fetchGPSLocation,
            icon: const Icon(Icons.my_location_rounded, size: 14),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          ),
        ],
      ),
    );
  }
}
