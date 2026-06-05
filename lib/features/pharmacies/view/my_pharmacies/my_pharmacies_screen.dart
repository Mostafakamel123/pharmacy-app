// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:Elaaj/features/pharmacies/model/user_pharmacy_model.dart';
import 'package:Elaaj/features/pharmacies/view/create_pharmacy/create_pharmacy_screen.dart';
import 'package:Elaaj/features/pharmacies/view/edit_pharmacy/edit_pharmacy_screen.dart';
import 'package:Elaaj/features/pharmacies/view/pharmacy_admins/pharmacy_admins_screen.dart';

/// Screen displaying all pharmacies owned/managed by the user
class MyPharmaciesScreen extends ConsumerStatefulWidget {
  const MyPharmaciesScreen({super.key});

  @override
  ConsumerState<MyPharmaciesScreen> createState() => _MyPharmaciesScreenState();
}

class _MyPharmaciesScreenState extends ConsumerState<MyPharmaciesScreen> {
  @override
  void initState() {
    super.initState();
    // Load user's pharmacies on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myPharmaciesProvider.notifier).loadUserPharmacies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncPharmacies = ref.watch(myPharmaciesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pharmacies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(myPharmaciesProvider.notifier).loadUserPharmacies();
            },
          ),
        ],
      ),
      body: asyncPharmacies.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load pharmacies',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () {
                  ref.read(myPharmaciesProvider.notifier).loadUserPharmacies();
                },
              ),
            ],
          ),
        ),
        data: (pharmacies) {
          if (pharmacies.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildPharmaciesList(context, pharmacies);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePharmacyScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_business),
        label: const Text('New Pharmacy'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 96,
              color: AppColors.primaryBlue.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pharmacies Yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first pharmacy to start managing\nyour business and serving customers.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePharmacyScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Create Pharmacy'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmaciesList(BuildContext context, List<UserPharmacyModel> pharmacies) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(myPharmaciesProvider.notifier).loadUserPharmacies();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pharmacies.length,
        itemBuilder: (context, index) {
          final pharmacy = pharmacies[index];
          return _buildPharmacyCard(context, pharmacy);
        },
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, UserPharmacyModel pharmacy) {
    final isOwner = pharmacy.ownerUserId == ref.read(currentUserIdProvider);
    final isAdmin = pharmacy.isAdmin(ref.read(currentUserIdProvider));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPharmacyScreen(pharmacy: pharmacy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: pharmacy.coverImageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        pharmacy.coverImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        cacheHeight: 240,
                        errorBuilder: (context, error, stack) {
                          return _buildPlaceholder(pharmacy.name);
                        },
                      ),
                    )
                  : _buildPlaceholder(pharmacy.name),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pharmacy.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user,
                                size: 14,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isOwner && isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 14,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  if (pharmacy.description != null && pharmacy.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      pharmacy.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.primaryCyan,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryCyan,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  if (pharmacy.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppColors.primaryCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pharmacy.phone!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryCyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${pharmacy.adminUserIds.length + 1} Admin${pharmacy.adminUserIds.length + 1 > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryCyan,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPharmacyScreen(
                                    pharmacy: pharmacy,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PharmacyAdminsScreen(
                                    pharmacy: pharmacy,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.people, size: 16),
                            label: const Text('Admins'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 48,
            color: AppColors.primaryBlue.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

