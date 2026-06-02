// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/profile/controller/profile_providers.dart';
import 'package:pharmacy_app/core/config/env_config.dart';
import 'package:pharmacy_app/core/services/geocoding_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Delay initialization until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).asData?.value;
      if (profile != null) {
        ref.read(editFormProvider.notifier).initialize(
              name: profile.name,
              dateOfBirth: profile.dateOfBirth ?? '',
              location: profile.location ?? '',
              latitude: profile.latitude ?? 0.0,
              longitude: profile.longitude ?? 0.0,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(editFormProvider);
    final profile = ref.read(profileProvider).asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor:
            isDark ? DarkColors.background : LightColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: formState.isSaving
                ? null
                : () async {
                    final success =
                        await ref.read(editFormProvider.notifier).save();
                    if (success) {
                      final name = formState.name;
                      final dateOfBirth = formState.dateOfBirth;
                      final location = formState.location;
                      final latitude = formState.latitude;
                      final longitude = formState.longitude;
                      final imagePath = formState.imagePath;
                      await ref
                          .read(profileProvider.notifier)
                          .updateProfile(
                            name: name,
                            dateOfBirth: dateOfBirth,
                            imagePath: imagePath,
                            address: location,
                            latitude: latitude,
                            longitude: longitude,
                          );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
            child: formState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar section
            Center(
              child: GestureDetector(
                onTap: () => _showImageSourceBottomSheet(context, ref),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? DarkColors.divider
                              : LightColors.divider,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: formState.imagePath != null
                            ? Image.file(
                                File(formState.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : (profile?.avatarUrl != null &&
                                    profile!.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    profile.avatarUrl!.startsWith('http')
                                        ? profile.avatarUrl!
                                        : '${EnvConfig.apiBaseUrl}${profile.avatarUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.camera_alt_rounded,
                                          size: 32,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Name field
            _InputField(
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_rounded,
              initialValue: formState.name,
              onChanged: (v) =>
                  ref.read(editFormProvider.notifier).updateName(v),
              error: formState.errors['name'],
            ),
            const SizedBox(height: 16),

            // Date of Birth field
            _DatePickerField(
              label: 'Date of Birth',
              value: formState.dateOfBirth,
              onChanged: (dateStr) =>
                  ref.read(editFormProvider.notifier).updateDateOfBirth(dateStr),
              error: formState.errors['dateOfBirth'],
            ),
            const SizedBox(height: 16),

            // Location field (Address)
            _InputField(
              label: 'Address',
              hint: 'Enter your city or address',
              icon: Icons.location_on_rounded,
              initialValue: formState.location,
              onChanged: (v) =>
                  ref.read(editFormProvider.notifier).updateLocation(v),
              error: formState.errors['location'],
            ),
            const SizedBox(height: 20),

            // GPS Locator section
            _GPSLocatorWidget(
              latitude: formState.latitude,
              longitude: formState.longitude,
              onCoordinatesFetched: (lat, lng) =>
                  ref.read(editFormProvider.notifier).updateCoordinates(lat, lng),
              onAddressFetched: (address) =>
                  ref.read(editFormProvider.notifier).updateLocation(address),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceBottomSheet(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                'Select Profile Picture Source',
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
                      _pickImage(ImageSource.camera, ref);
                    },
                  ),
                  _buildSourceButton(
                    theme: theme,
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery, ref);
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

  Future<void> _pickImage(ImageSource source, WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        ref.read(editFormProvider.notifier).updateImagePath(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final initialDate = DateTime.tryParse(value) ?? DateTime(2000, 1, 1);
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: isDark
                        ? const ColorScheme.dark(
                            primary: AppColors.primaryBlue,
                            onPrimary: Colors.white,
                            surface: DarkColors.card,
                            onSurface: Colors.white,
                          )
                        : const ColorScheme.light(
                            primary: AppColors.primaryBlue,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formatted =
                  "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              onChanged(formatted);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? DarkColors.card : LightColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: error != null
                    ? AppColors.accentRed
                    : isDark
                        ? DarkColors.divider
                        : LightColors.divider,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cake_rounded,
                  color: error != null
                      ? AppColors.accentRed
                      : isDark
                          ? const Color(0xFF90CAF9)
                          : AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  value.isNotEmpty ? value : 'Select your date of birth',
                  style: TextStyle(
                    color: value.isNotEmpty
                        ? (isDark ? DarkColors.textPrimary : LightColors.textPrimary)
                        : (isDark ? DarkColors.textHint : LightColors.textHint),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isDark ? DarkColors.textHint : DarkColors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error!,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _GPSLocatorWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Function(double lat, double lng) onCoordinatesFetched;
  final Function(String address)? onAddressFetched;

  const _GPSLocatorWidget({
    required this.latitude,
    required this.longitude,
    required this.onCoordinatesFetched,
    this.onAddressFetched,
  });

  @override
  State<_GPSLocatorWidget> createState() => _GPSLocatorWidgetState();
}

class _GPSLocatorWidgetState extends State<_GPSLocatorWidget> {
  bool _loading = false;
  String _error = '';

  Future<void> _fetchGPS() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission was denied.';
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied.';
          _loading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      widget.onCoordinatesFetched(position.latitude, position.longitude);

      // Perform geocoding to resolve address
      if (widget.onAddressFetched != null) {
        final address = await GeocodingService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (address != null) {
          widget.onAddressFetched!(address);
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch GPS coordinates: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location Coordinates',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _error.isNotEmpty
                  ? AppColors.accentRed
                  : isDark
                      ? DarkColors.divider
                      : LightColors.divider,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed_rounded,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latitude: ${widget.latitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Longitude: ${widget.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded),
                      color: AppColors.primaryBlue,
                      onPressed: _fetchGPS,
                      tooltip: 'Get Current Location',
                    ),
                ],
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _error,
                  style: const TextStyle(
                    color: AppColors.accentRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? error;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.initialValue,
    required this.onChanged,
    this.error,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.error != null
                  ? AppColors.accentRed
                  : isDark
                      ? DarkColors.divider
                      : LightColors.divider,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: isDark ? DarkColors.textHint : LightColors.textHint,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: widget.error != null
                    ? AppColors.accentRed
                    : isDark
                        ? const Color(0xFF90CAF9)
                        : AppColors.primaryBlue,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.error!,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
