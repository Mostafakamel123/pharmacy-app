// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_request_providers.dart';
import 'package:Elaaj/features/pharmacy_mode/view/screens/pharmacy_prescription_detail_screen.dart';
import 'package:Elaaj/features/pharmacy_mode/widgets/pharmacy_drawer.dart';

/// Pharmacy Orders Screen
/// 
/// Displays list of user requests/orders for the pharmacy.
/// Allows accepting/rejecting orders and tracking status.
class PharmacyOrdersScreen extends ConsumerStatefulWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  ConsumerState<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends ConsumerState<PharmacyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pharmacyModeState = ref.watch(pharmacyModeProvider);
    final currentPharmacy = pharmacyModeState.currentPharmacy;

    // If no pharmacy selected, show empty state
    if (currentPharmacy == null) {
      return Scaffold(
        drawer: PharmacyDrawer(null),
        appBar: AppBar(
          title: const Text('Orders'),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: PharmacyDrawer(currentPharmacy),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Orders & Requests'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Completed'),
          ],
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? DarkColors.textSecondary
              : LightColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrdersList(status: OrderStatus.pending, pharmacy: currentPharmacy),
          _OrdersList(status: OrderStatus.accepted, pharmacy: currentPharmacy),
          _OrdersList(status: OrderStatus.completed, pharmacy: currentPharmacy),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'No Pharmacy Selected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select a pharmacy from the drawer to manage orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum OrderStatus { pending, accepted, completed }

class _OrdersList extends ConsumerWidget {
  final OrderStatus status;
  final dynamic pharmacy;

  const _OrdersList({
    required this.status,
    required this.pharmacy,
  });

  void _showOfferDialog(BuildContext context, WidgetRef ref, String prescriptionId, String pharmacyId) {
    final priceController = TextEditingController();
    final msgController = TextEditingController();
    bool available = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Submit Price Offer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Total Price (EGP)',
                        hintText: 'e.g. 150',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: msgController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Message',
                        hintText: 'e.g. Fully available, fast delivery',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: available,
                          onChanged: (val) {
                            setState(() {
                              available = val ?? true;
                            });
                          },
                        ),
                        const Text('All items are available'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final double price = double.tryParse(priceController.text) ?? 0.0;
                    final String message = msgController.text;

                    final success = await ref.read(pharmacyActionsProvider).submitReply(
                      prescriptionId: prescriptionId,
                      pharmacyId: pharmacyId,
                      message: message,
                      totalPrice: price,
                      isAvailable: available,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Offer submitted successfully!' : 'Error submitting offer.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Offer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(
      nearbyPrescriptionsProvider((pharmacyId: pharmacy.id, radius: 5.0)),
    );
    final localState = ref.watch(pharmacyPrescriptionsLocalProvider(pharmacy.id));
    final rejectedIds = localState.rejectedIds;
    final offeredDetails = localState.offeredDetails;
    final offeredIds = offeredDetails.keys.toSet();

    return prescriptionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (presList) {
        final List<dynamic> filteredList;
        if (status == OrderStatus.pending) {
          filteredList = presList.where((p) {
            final id = p['id'] as String? ?? '';
            final isRejected = rejectedIds.contains(id);
            final isOffered = offeredIds.contains(id);
            final isPendingStatus = p['status'] == null || p['status'] == 0 || p['status'] == 1;
            return !isRejected && !isOffered && isPendingStatus;
          }).toList();
        } else if (status == OrderStatus.accepted) {
          filteredList = presList.where((p) {
            final id = p['id'] as String? ?? '';
            final isRejected = rejectedIds.contains(id);
            final isOffered = offeredIds.contains(id);
            final isAcceptedStatus = p['status'] == 2 || p['status'] == 3;
            return !isRejected && (isAcceptedStatus || isOffered);
          }).toList();
        } else {
          filteredList = presList.where((p) {
            final id = p['id'] as String? ?? '';
            final isRejected = rejectedIds.contains(id);
            final isCancelledStatus = p['status'] == 5 || p['status'] == 4;
            return isRejected || isCancelledStatus;
          }).toList();
        }

        if (filteredList.isEmpty) {
          return _buildEmptyList(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            final String id = item['id'] as String? ?? '';
            final String notes = item['notes'] as String? ?? 'Prescription Request';
            final String displayId = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();
            final String customer = 'Patient #$displayId';
            final int pStatus = item['status'] as int? ?? 0;
            
            final offerDetail = offeredDetails[id];
            final String priceText;
            if (offerDetail != null) {
              priceText = '${offerDetail['price']} EGP';
            } else {
              priceText = 'No price offered yet';
            }

            final isRejectedItem = rejectedIds.contains(id);

            final orderItem = {
              'id': displayId,
              'fullId': id,
              'customer': customer,
              'items': notes,
              'time': 'Nearby Request',
              'price': priceText,
              'status': pStatus == 2 
                  ? 'Preparing' 
                  : (pStatus == 3 
                      ? 'Ready' 
                      : (isRejectedItem
                          ? 'Rejected'
                          : (offerDetail != null ? 'Offered' : null))),
            };

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PharmacyPrescriptionDetailScreen(
                      prescription: item,
                      pharmacy: pharmacy,
                    ),
                  ),
                );
              },
              child: _OrderCard(
                order: orderItem,
                onAccept: () {
                  _showOfferDialog(context, ref, id, pharmacy.id);
                },
                onReject: () async {
                  // Call backend API to change status to 4 (Rejected/Declined)
                  await ref.read(pharmacyActionsProvider).changeStatus(
                    prescriptionId: id,
                    status: 4,
                  );
                  
                  await ref.read(pharmacyPrescriptionsLocalProvider(pharmacy.id).notifier)
                      .rejectPrescription(id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request Rejected / تم رفض الطلب')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message;

    switch (status) {
      case OrderStatus.pending:
        message = 'No pending orders';
        break;
      case OrderStatus.accepted:
        message = 'No accepted orders';
        break;
      case OrderStatus.completed:
        message = 'No completed orders';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OrderCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order['id']}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                order['price'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order['customer'] as String,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order['items'] as String,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['time'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? DarkColors.textHint : LightColors.textHint,
                ),
              ),
              if (order['status'] != null) ...[
                (() {
                  Color badgeColor = AppColors.primaryBlue;
                  final String s = order['status'] as String;
                  if (s == 'Rejected') {
                    badgeColor = AppColors.accentRed;
                  } else if (s == 'Ready' || s == 'Offered') {
                    badgeColor = AppColors.primaryGreen;
                  }
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  );
                })(),
              ],
            ],
          ),
          if (order['status'] == null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentRed,
                      side: const BorderSide(color: AppColors.accentRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
