import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/features/auth/service/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceImpl();
});
