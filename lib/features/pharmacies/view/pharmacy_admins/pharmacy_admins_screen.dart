// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/auth/service/auth_service.dart';
import 'package:pharmacy_app/features/auth/controller/auth_providers.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

/// Provider for user search results
final userSearchProvider = StateNotifierProvider<UserSearchNotifier, AsyncValue<List<UserSearchResult>>>((ref) {
  final authService = ref.read(authServiceProvider);
  return UserSearchNotifier(authService);
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

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      userId: (json['id'] ?? json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: json['fullName'] as String?,
    );
  }
}

class UserSearchNotifier extends StateNotifier<AsyncValue<List<UserSearchResult>>> {
  final AuthService _authService;

  UserSearchNotifier(this._authService) : super(const AsyncValue.data([]));
  
  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    
    state = const AsyncValue.loading();
    
    try {
      final results = await _authService.searchUsers(query: query.trim());
      final mappedResults = results.map((e) => UserSearchResult.fromJson(e)).toList();
      state = AsyncValue.data(mappedResults);
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
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwner = widget.pharmacy.ownerUserId == currentUserId || widget.pharmacy.ownerUserId.isEmpty;

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
class _AddAdminDialog extends ConsumerStatefulWidget {
  final String pharmacyId;
  final AuthService authService;
  final VoidCallback onAdminAdded;

  const _AddAdminDialog({
    required this.pharmacyId,
    required this.authService,
    required this.onAdminAdded,
  });

  @override
  ConsumerState<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends ConsumerState<_AddAdminDialog> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  String _selectedUserId = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(userSearchProvider.notifier).searchUsers(query);
      }
    });
  }

  Future<void> _submit(UserSearchResult user) async {
    setState(() {
      _isLoading = true;
      _selectedUserId = user.userId;
      _error = null;
    });

    try {
      // Call the assign pharmacy admin API with actual user ID
      await widget.authService.assignPharmacyAdmin(
        userId: user.userId,
        pharmacyId: widget.pharmacyId,
      );

      if (mounted) {
        widget.onAdminAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.fullName ?? user.email} added as admin successfully'),
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
          _selectedUserId = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResultState = ref.watch(userSearchProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Pharmacy Admin'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search User',
                hintText: 'Enter user name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(userSearchProvider.notifier).searchUsers('');
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) {
                setState(() {});
                _onSearchChanged(val);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Search results area
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 240,
                minHeight: 100,
              ),
              child: searchResultState.when(
                data: (users) {
                  if (_searchController.text.trim().isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 48,
                            color: AppColors.primaryBlue.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Search for users by name or email',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: LightColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.accentRed.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No users found matching "${_searchController.text}"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: LightColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isAssigningThis = _isLoading && _selectedUserId == user.userId;
                      final initials = (user.fullName ?? user.email).trim().substring(0, 1).toUpperCase();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.15),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          title: Text(
                            user.fullName ?? 'No Name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: LightColors.textSecondary,
                            ),
                          ),
                          trailing: isAssigningThis
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton(
                                  onPressed: _isLoading ? null : () => _submit(user),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: const Size(60, 32),
                                  ),
                                  child: const Text('Add'),
                                ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: AppColors.accentRed),
                  ),
                ),
              ),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.accentRed,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
