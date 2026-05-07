import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';

/// A toggle widget to switch between Personal and Pharmacy modes
class PharmacyModeToggle extends ConsumerWidget {
  const PharmacyModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PERF FIX: Use .select() to watch only the specific fields needed instead of full state
    final isPersonalMode = ref.watch(pharmacyModeProvider.select((state) => state.isPersonalMode));
    final userPharmacies = ref.watch(pharmacyModeProvider.select((state) => state.userPharmacies));
    final currentPharmacy = ref.watch(pharmacyModeProvider.select((state) => state.currentPharmacy));
    final notifier = ref.read(pharmacyModeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Personal Mode Button
          _ModeButton(
            label: 'Personal',
            icon: Icons.person_outline,
            isActive: isPersonalMode,
            onTap: () => notifier.switchToPersonalMode(),
          ),
          const SizedBox(width: 4),
          // Pharmacy Mode Button
          _ModeButton(
            label: 'Pharmacy',
            icon: Icons.business_outlined,
            isActive: !isPersonalMode,
            onTap: () {
              if (userPharmacies.isEmpty) {
                _showNoPharmacyDialog(context, ref);
              } else {
                _showPharmacySelector(context, ref, userPharmacies, currentPharmacy);
              }
            },
            badgeCount: userPharmacies.length,
          ),
        ],
      ),
    );
  }

  void _showNoPharmacyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Pharmacies'),
        content: const Text(
          "You don't have any pharmacies yet. Create one to start managing!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to create pharmacy screen
              // context.pushNamed('createPharmacy');
            },
            child: const Text('Create Pharmacy'),
          ),
        ],
      ),
    );
  }

  void _showPharmacySelector(BuildContext context, WidgetRef ref, List<dynamic> userPharmacies, dynamic currentPharmacy) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Pharmacy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                itemCount: userPharmacies.length,
                itemExtent: 72.0, // PERF FIX: Add itemExtent for fixed-height items to improve scroll performance
                addAutomaticKeepAlives: false, // PERF FIX: Disable keep-alives for lightweight list items
                addRepaintBoundaries: true, // PERF FIX: Enable repaint boundaries for better rendering
                itemBuilder: (context, index) {
                  final pharmacy = userPharmacies[index];
                  final isCurrentPharmacy = 
                      currentPharmacy?.id == pharmacy.id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrentPharmacy
                          ? Colors.blue
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.business,
                        color: isCurrentPharmacy ? Colors.white : Colors.grey,
                      ),
                    ),
                    title: Text(pharmacy.name),
                    subtitle: Text(pharmacy.address),
                    trailing: isCurrentPharmacy
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () {
                      ref
                          .read(pharmacyModeProvider.notifier)
                          .switchToPharmacyMode(pharmacy);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to create pharmacy screen
                },
                icon: const Icon(Icons.add_business),
                label: const Text('Create New Pharmacy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final int? badgeCount;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0 && !isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
