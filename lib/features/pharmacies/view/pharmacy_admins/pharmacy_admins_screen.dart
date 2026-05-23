// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/auth/service/auth_service.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

/// Provider for user search results
final userSearchProvider = StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserSearchResult>>>((ref) {
  return UserSearchNotifier();
});

class UserSearchResult {
  final String userId;
  final String email;
  final String? fullName;
  
  const UserSearchResult({
    required this.userId,
    required this.email,
    this.fullName,
  });
}

class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserSearchResult>>> {
  UserSearchNotifier() : super(const AsyncValue.data([]));
  
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      // TODO: Implement actual user search API
      // For now, this is a placeholder
      await Future.delayed(const Duration(milliseconds: 300));
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Screen for managing pharmacy admins
class PharmacyAdminsScreen extends ConsumerStatefulWidget {
  final UserPharmacyModel pharmacy;

  const PharmacyAdminsScreen({
    super.key,
    required this.pharmacy,
  });

  @override
  ConsumerState<PharmacyAdminsScreen> createState() => _PharmacyAdminsScreenState();
}

class _PharmacyAdminsScreenState extends ConsumerState<PharmacyAdminsScreen> {
  bool _isLoading = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final AuthService _authService = AuthServiceImpl();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _removeAdmin(String userId) async {
    if (userId == widget.pharmacy.ownerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove the owner'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Are you sure you want to remove this admin?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(myPharmaciesProvider.notifier).removeAdmin(
            widget.pharmacy.id,
            userId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ? 'Admin removed successfully' : 'Failed to remove admin',
            ),
            backgroundColor: result ? AppColors.primaryGreen : AppColors.accentRed,
          ),
        );
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

  Future<void> _addAdmin() async {
    showDialog(
      context: context,
      builder: (context) => _AddAdminDialog(
        pharmacyId: widget.pharmacy.id,
        authService: _authService,
        onAdminAdded: () {
          setState(() {});
          ref.invalidate(myPharmaciesProvider);
        },
      ),
    );
  }

  Future<void> _transferOwnership(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Ownership'),
        content: const Text(
          'Are you sure you want to transfer ownership? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
            ),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: Implement ownership transfer API
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ownership transfer functionality coming soon'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAdminIds = widget.pharmacy.allAdminIds;
    final currentUserId = ref.read(currentUserIdProvider);
    final isOwner = widget.pharmacy.ownerUserId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        // subtitle: Text(widget.pharmacy.name),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.primaryBlue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${allAdminIds.length} Total Admins',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Manage who can administer this pharmacy',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Admins List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: allAdminIds.length,
                    itemBuilder: (context, index) {
                      final userId = allAdminIds[index];
                      final isOwnerUser = userId == widget.pharmacy.ownerUserId;
                      
                      // Filter by search query
                      if (_searchQuery.isNotEmpty &&
                          !userId.toLowerCase().contains(_searchQuery)) {
                        return const SizedBox.shrink();
                      }

                      return _buildAdminTile(
                        userId,
                        isOwnerUser,
                        isOwner && !isOwnerUser,
                        theme,
                      );
                    },
                  ),
          ),

          // Add Admin Button
          if (isOwner)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addAdmin,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add New Admin'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(String userId, bool isOwnerUser, bool canRemove, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOwnerUser
              ? AppColors.primaryBlue
              : AppColors.accentPurple,
          child: Icon(
            isOwnerUser ? Icons.verified_user : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          userId, // TODO: Replace with actual user name
          style: TextStyle(
            fontWeight: isOwnerUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            if (isOwnerUser) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Owner',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPurple,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              'ID: ${userId.substring(0, 8)}...',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: canRemove
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _removeAdmin(userId);
                  } else if (value == 'transfer') {
                    _transferOwnership(userId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: AppColors.accentRed),
                        SizedBox(width: 8),
                        Text('Remove Admin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: AppColors.accentYellow),
                        SizedBox(width: 8),
                        Text('Transfer Ownership'),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

/// Dialog for adding a new admin to pharmacy
class _AddAdminDialog extends StatefulWidget {
  final String pharmacyId;
  final AuthService authService;
  final VoidCallback onAdminAdded;

  const _AddAdminDialog({
    required this.pharmacyId,
    required this.authService,
    required this.onAdminAdded,
  });

  @override
  State<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<_AddAdminDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter user email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, we need to get the user ID from email
      // This requires a user lookup API - for now we'll use the email as userId
      // In production, you should call an API to get the actual user ID
      
      // Call the assign pharmacy admin API
      await widget.authService.assignPharmacyAdmin(
        userId: email, // TODO: Replace with actual user ID lookup
        pharmacyId: widget.pharmacyId,
      );

      if (mounted) {
        widget.onAdminAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin added successfully'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
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
    return AlertDialog(
      title: const Text('Add Admin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'User Email',
              hintText: 'Enter user email address',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Note: Enter the exact email of the user you want to add as admin.',
            style: TextStyle(
              fontSize: 12,
              color: LightColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
