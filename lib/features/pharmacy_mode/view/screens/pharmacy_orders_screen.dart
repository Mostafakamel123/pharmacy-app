// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:pharmacy_app/features/pharmacy_mode/widgets/pharmacy_drawer.dart';

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
        appBar: AppBar(
          title: const Text('Orders'),
          centerTitle: true,
        ),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: PharmacyDrawer(currentPharmacy),
      appBar: AppBar(
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

class _OrdersList extends StatelessWidget {
  final OrderStatus status;
  final dynamic pharmacy;

  const _OrdersList({
    required this.status,
    required this.pharmacy,
  });

  @override
  Widget build(BuildContext context) {
    // Sample data - replace with actual data from provider
    final orders = _getSampleOrders();

    if (orders.isEmpty) {
      return _buildEmptyList(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(
          order: order,
          onAccept: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order #${order['id']} accepted')),
            );
          },
          onReject: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order #${order['id']} rejected')),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getSampleOrders() {
    switch (status) {
      case OrderStatus.pending:
        return [
          {
            'id': '1234',
            'customer': 'Ahmed Mohamed',
            'items': 'Paracetamol 500mg x2, Ibuprofen x1',
            'time': '10 min ago',
            'price': '45 EGP',
          },
          {
            'id': '1235',
            'customer': 'Fatima Ali',
            'items': 'Vitamin C 1000mg x3',
            'time': '25 min ago',
            'price': '90 EGP',
          },
          {
            'id': '1236',
            'customer': 'Mohamed Hassan',
            'items': 'Amoxicillin 500mg x1, Panadol Extra x2',
            'time': '1 hour ago',
            'price': '75 EGP',
          },
        ];
      case OrderStatus.accepted:
        return [
          {
            'id': '1230',
            'customer': 'Sara Ibrahim',
            'items': 'Aspirin 100mg x2',
            'time': '2 hours ago',
            'price': '30 EGP',
            'status': 'Preparing',
          },
        ];
      case OrderStatus.completed:
        return [
          {
            'id': '1225',
            'customer': 'Omar Khalid',
            'items': 'Nurofen 400mg x1',
            'time': 'Yesterday',
            'price': '35 EGP',
          },
          {
            'id': '1220',
            'customer': 'Layla Mahmoud',
            'items': 'Multivitamin x2, Zinc x1',
            'time': '2 days ago',
            'price': '120 EGP',
          },
        ];
    }
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
              Text(
                'Order #${order['id']}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                ),
              ),
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
              if (order['status'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    order['status'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
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
      ),
    );
  }
}
