import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';

/// Authentication boundary. Existing mock routes intentionally do not use it yet.
abstract class AuthService {
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({required String email, required String password});

  Future<void> signOut();

  String? get currentUserId;

  Stream<String?> authStateChanges();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Stream<String?> authStateChanges() =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user.id);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }
}

/// Local-first fallback used until Supabase credentials are configured.
class LocalStubAuthService implements AuthService {
  const LocalStubAuthService();

  @override
  String? get currentUserId => null;

  @override
  Stream<String?> authStateChanges() => Stream<String?>.value(null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}
}

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const LocalStubAuthService()
      : SupabaseAuthService(client);
});
