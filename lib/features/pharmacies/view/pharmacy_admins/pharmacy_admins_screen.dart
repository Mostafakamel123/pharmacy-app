// ignore_for_file: deprecated_member_use

import 'dart:async'; // PERF FIX: Added for Timer-based debounce
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:pharmacy_app/features/pharmacies/model/user_pharmacy_model.dart';

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
  Timer? _debounceTimer; // PERF FIX: Timer for debouncing search input

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // PERF FIX: Cancel timer to prevent memory leaks
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
    // TODO: Implement user search and selection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search User',
                hintText: 'Enter user email or name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'User search functionality will be implemented here.',
              style: TextStyle(color: LightColors.textSecondary),
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
              // TODO: Add selected user as admin
            },
            child: const Text('Add'),
          ),
        ],
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
                // PERF FIX: Debounce search input to reduce unnecessary rebuilds
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  }
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
                    addAutomaticKeepAlives: false, // PERF FIX: Items don't need to keep state
                    addRepaintBoundaries: true, // PERF FIX: Enable repaint isolation
                    itemBuilder: (context, index) {
                      final userId = allAdminIds[index];
                      final isOwnerUser = userId == widget.pharmacy.ownerUserId;
                      
                      // Filter by search query
                      if (_searchQuery.isNotEmpty &&
                          !userId.toLowerCase().contains(_searchQuery)) {
                        return const SizedBox.shrink();
                      }

                      return RepaintBoundary( // PERF FIX: Isolate each tile's repaints
                        child: _buildAdminTile(
                          userId,
                          isOwnerUser,
                          isOwner && !isOwnerUser,
                          theme,
                        ),
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
      key: ValueKey(userId), // PERF FIX: Stable key to preserve widget state
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
