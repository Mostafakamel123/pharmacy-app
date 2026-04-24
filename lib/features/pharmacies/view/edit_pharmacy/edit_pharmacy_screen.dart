import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

/// Screen for editing pharmacy details
class EditPharmacyScreen extends ConsumerStatefulWidget {
  final UserPharmacyModel pharmacy;

  const EditPharmacyScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  ConsumerState<EditPharmacyScreen> createState() => _EditPharmacyScreenState();
}

class _EditPharmacyScreenState extends ConsumerState<EditPharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _licenseNumberController;
  
  late double _latitude;
  late double _longitude;
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pharmacy.name);
    _descriptionController = TextEditingController(text: widget.pharmacy.description ?? '');
    _addressController = TextEditingController(text: widget.pharmacy.address);
    _phoneController = TextEditingController(text: widget.pharmacy.phone ?? '');
    _emailController = TextEditingController(text: widget.pharmacy.email ?? '');
    _websiteController = TextEditingController(text: widget.pharmacy.website ?? '');
    _licenseNumberController = TextEditingController(text: widget.pharmacy.licenseNumber ?? '');
    _latitude = widget.pharmacy.latitude;
    _longitude = widget.pharmacy.longitude;
    _isActive = widget.pharmacy.isActive;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Enter latitude',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _latitude.toString()),
              onChanged: (value) {
                _latitude = double.tryParse(value) ?? _latitude;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Enter longitude',
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _longitude.toString()),
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
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Update Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePharmacy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pharmacy'),
        content: const Text(
          'Are you sure you want to delete this pharmacy? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(myPharmaciesProvider.notifier).deletePharmacy(
            widget.pharmacy.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ? 'Pharmacy deleted successfully' : 'Failed to delete pharmacy',
            ),
            backgroundColor: result ? AppColors.primaryGreen : AppColors.accentRed,
          ),
        );

        if (result) {
          Navigator.pop(context); // Return to previous screen
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPharmacy = widget.pharmacy.copyWith(
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
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );

      final result = await ref.read(myPharmaciesProvider.notifier).updatePharmacy(updatedPharmacy);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ? 'Pharmacy updated successfully' : 'Failed to update pharmacy',
            ),
            backgroundColor: result ? AppColors.primaryGreen : AppColors.accentRed,
          ),
        );

        if (result) {
          Navigator.pop(context, updatedPharmacy);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.read(currentUserIdProvider);
    final isOwner = widget.pharmacy.ownerUserId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pharmacy'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Pharmacy',
              onPressed: _isLoading ? null : _deletePharmacy,
              color: AppColors.accentRed,
            ),
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Header
            Card(
              color: AppColors.primaryBlue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pharmacy.name,
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            'Update pharmacy information',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Basic Information Section
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: AppSpacing.sm),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Pharmacy Name *',
                hintText: 'Enter pharmacy name',
                prefixIcon: Icon(Icons.business),
              ),
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
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description about your pharmacy',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Active Status Toggle
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: Text(_isActive ? 'Visible to customers' : 'Hidden from customers'),
              value: _isActive,
              onChanged: isOwner
                  ? (value) {
                      setState(() {
                        _isActive = value;
                      });
                    }
                  : null,
              secondary: Icon(
                _isActive ? Icons.visibility : Icons.visibility_off,
                color: _isActive ? AppColors.primaryGreen : LightColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Contact Information Section
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: AppSpacing.sm),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                hintText: 'Enter full address',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            InkWell(
              onTap: _selectLocation,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border.all(color: LightColors.divider),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Coordinates',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'Lat: $_latitude, Lng: $_longitude',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit, size: 16, color: LightColors.textSecondary),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+20 2 1234 5678',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
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
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'www.pharmacy.com',
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // License Information Section
            _buildSectionTitle('License Information'),
            const SizedBox(height: AppSpacing.sm),
            
            TextFormField(
              controller: _licenseNumberController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                hintText: 'Pharmacy license number',
                prefixIcon: Icon(Icons.verified_user),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxxl),
            
            // Metadata Section
            _buildSectionTitle('Information'),
            const SizedBox(height: AppSpacing.sm),
            
            _buildInfoRow('Created', _formatDate(widget.pharmacy.createdAt)),
            if (widget.pharmacy.updatedAt != null) ...[
              _buildInfoRow('Last Updated', _formatDate(widget.pharmacy.updatedAt!)),
            ],
            _buildInfoRow('Total Admins', '${widget.pharmacy.adminUserIds.length + 1}'),
            
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: LightColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
