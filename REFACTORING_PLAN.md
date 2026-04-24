# Flutter App Refactoring Plan

## 🎯 Goal: Single Role Architecture with Pharmacy Mode

### Current State Analysis:
- Two roles: `UserRole.patient` and `UserRole.pharmacy`
- Role-based navigation in `PremiumNavShell`
- Separate nav configurations: `PatientNavItems` and `PharmacyNavItems`
- Role enum in `core/utils/user_role.dart`

---

## 📋 Refactoring Steps:

### Step 1: Remove Role Enum & Role-Based Logic
**Files to modify:**
- `/workspace/lib/core/utils/user_role.dart` → Delete or repurpose
- `/workspace/lib/core/utils/navigation_config.dart` → Remove role-specific nav items
- `/workspace/lib/features/navigation/widgets/premium_nav_shell.dart` → Remove role parameter
- `/workspace/lib/core/routing/app_router.dart` → Remove role-based routing

### Step 2: Create New Pharmacy Model (User-Owned Pharmacies)
**New file:** `/workspace/lib/features/pharmacies/model/user_pharmacy_model.dart`
- id, name, description, logoUrl
- ownerUserId, adminUserIds (List<String>)
- createdAt, updatedAt

### Step 3: Create Pharmacy Mode State Management
**New file:** `/workspace/lib/features/pharmacy_mode/controller/pharmacy_mode_provider.dart`
- Track current mode: Personal vs Pharmacy
- Track selected pharmacy ID
- Methods to switch modes

### Step 4: Update Navigation Config
**Modify:** `/workspace/lib/core/utils/navigation_config.dart`
- Single unified `UserNavItems` class
- Remove `PatientNavItems` and `PharmacyNavItems`
- Keep only user-facing navigation

### Step 5: Update API Endpoints for Pharmacy Management
**Modify:** `/workspace/lib/core/constants/api_endpoints.dart`
- Add pharmacy CRUD endpoints
- Add admin management endpoints

### Step 6: Clean Up Dead Code
- Remove unused imports
- Remove placeholder screens for pharmacy role
- Update all references

---

## 📁 New Folder Structure:

```
lib/
├── core/
│   ├── utils/
│   │   └── navigation_config.dart       (Unified nav config)
│   ├── constants/
│   │   └── api_endpoints.dart           (Updated with pharmacy APIs)
│   └── routing/
│       └── app_router.dart              (Simplified routing)
│
├── features/
│   ├── pharmacy_mode/                   (NEW)
│   │   ├── controller/
│   │   │   └── pharmacy_mode_provider.dart
│   │   └── widgets/
│   │       └── pharmacy_mode_toggle.dart
│   │
│   ├── pharmacies/
│   │   ├── model/
│   │   │   ├── pharmacy_model.dart      (Existing - for nearby pharmacies)
│   │   │   └── user_pharmacy_model.dart (NEW - user-owned pharmacies)
│   │   ├── view/
│   │   │   ├── create_pharmacy_screen.dart
│   │   │   ├── my_pharmacies_screen.dart
│   │   │   └── pharmacy_admin_screen.dart
│   │   └── controller/
│   │       └── pharmacy_providers.dart
│   │
│   ├── navigation/
│   │   └── widgets/
│   │       └── premium_nav_shell.dart   (Refactored - no role param)
│   │
│   └── ... (other features remain similar)
```

---

## 🔧 Implementation Details:

### 1. UserPharmacyModel
```dart
class UserPharmacyModel {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String ownerUserId;
  final List<String> adminUserIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### 2. PharmacyModeProvider
```dart
enum AppMode { personal, pharmacy }

class PharmacyModeState {
  final AppMode currentMode;
  final UserPharmacyModel? currentPharmacy;
  final List<UserPharmacyModel> userPharmacies;
  // ... methods to switch mode, create pharmacy, etc.
}
```

### 3. Unified Navigation
```dart
class UserNavItems {
  static const List<NavItem> items = [
    NavItem(label: 'Home', icon: Icons.home, ...),
    NavItem(label: 'Posts', icon: Icons.article, ...),
    NavItem(label: 'Chat', icon: Icons.chat, ...),
    NavItem(label: 'Profile', icon: Icons.person, ...),
  ];
}
```

### 4. API Endpoints for Pharmacy Management
```dart
// POST /pharmacies - Create pharmacy
static const String createPharmacy = '$_baseUrl/pharmacies';

// GET /pharmacies/my - Get user's pharmacies  
static const String myPharmacies = '$_baseUrl/pharmacies/my';

// PUT /pharmacies/{id}/admins - Manage admins
static String managePharmacyAdmins(String id) => '$_baseUrl/pharmacies/$id/admins';
```

---

## ✅ Verification Checklist:

- [ ] UserRole enum removed/replaced
- [ ] PremiumNavShell no longer requires userRole
- [ ] Single unified BottomNavigationBar
- [ ] Pharmacy mode toggle implemented
- [ ] UserPharmacyModel created
- [ ] API endpoints for pharmacy management added
- [ ] No dead code or unused imports
- [ ] All tests pass
