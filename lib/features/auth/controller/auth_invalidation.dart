import 'package:flutter_riverpod/flutter_riverpod.dart';

// User-scoped feature providers — prefixes used where provider names collide
import 'package:Elaaj/features/profile/controller/profile_providers.dart';
import 'package:Elaaj/features/chat/controller/chat_providers.dart';
import 'package:Elaaj/features/home/controller/home_providers.dart' as home;
import 'package:Elaaj/features/posts/controller/posts_providers.dart';
import 'package:Elaaj/features/pharmacies/controller/my_pharmacies_provider.dart';
import 'package:Elaaj/features/pharmacies/controller/pharmacy_providers.dart' as pharmacy_prov;
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_dashboard_controller.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_request_providers.dart';
import 'package:Elaaj/features/prescription/controller/prescription_providers.dart' as prescription_prov;

/// Atomically invalidates every user-scoped provider in the app.
///
/// Call this inside [AuthNotifier.logout] (and any account-switch flow) **before**
/// clearing the [AuthState]. Riverpod will mark each provider as stale so that
/// the very next subscriber triggers a fresh build with clean state — no
/// manual `.refresh()` calls needed anywhere in the UI.
///
/// ⚠️  When adding new user-scoped providers in the future, register them here
/// and add a `/// USER-SCOPED` doc comment at the provider declaration site.
void invalidateAllUserProviders(Ref ref) {
  // ── Profile ───────────────────────────────────────────────────────────────
  ref.invalidate(profileProvider);
  ref.invalidate(editFormProvider);

  // ── Chat ──────────────────────────────────────────────────────────────────
  ref.invalidate(chatsProvider);
  ref.invalidate(chatMessagesProvider); // .family — invalidates all instances
  ref.invalidate(chatSearchQueryProvider);
  ref.invalidate(filteredChatsProvider);

  // ── Home ──────────────────────────────────────────────────────────────────
  // Note: nearbyPharmaciesProvider exists in home, pharmacies, and prescription
  // files under the same name — each is a distinct provider object.
  ref.invalidate(home.nearbyPharmaciesProvider);
  ref.invalidate(home.recentPostsProvider);

  // ── Posts ─────────────────────────────────────────────────────────────────
  ref.invalidate(postsFeedProvider);
  ref.invalidate(myPostsProvider);
  ref.invalidate(createPostFormProvider);
  ref.invalidate(postRepliesNotifierProvider); // .family — invalidates all instances
  ref.invalidate(bookmarkedPostsProvider);
  ref.invalidate(selectedCategoryProvider);

  // ── Pharmacies ────────────────────────────────────────────────────────────
  ref.invalidate(myPharmaciesProvider);
  ref.invalidate(pharmacy_prov.nearbyPharmaciesProvider);
  ref.invalidate(pharmacy_prov.favoritePharmaciesProvider);

  // ── Pharmacy Mode ─────────────────────────────────────────────────────────
  ref.invalidate(pharmacyModeProvider);
  ref.invalidate(pharmacyDashboardProvider);
  ref.invalidate(pharmacyPrescriptionsLocalProvider); // .family — invalidates all instances
  ref.invalidate(nearbyPrescriptionsProvider);        // .family — invalidates all instances

  // ── Prescriptions ─────────────────────────────────────────────────────────
  ref.invalidate(prescription_prov.nearbyPharmaciesProvider); // .family FutureProvider
  ref.invalidate(prescription_prov.routingStateNotifierProvider);
  ref.invalidate(prescription_prov.countdownTimerNotifierProvider);

  // NOTE: darkModeProvider is intentionally excluded — it is a per-device
  // preference, not per-user data.
}
