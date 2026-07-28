import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

bool _supabaseInitialized = false;

/// Initializes Supabase only when both compile-time credentials are supplied.
Future<void> initSupabase() async {
  if (!isSupabaseConfigured) return;
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  _supabaseInitialized = true;
}

/// The client is unavailable while local-only mode is active or init failed.
SupabaseClient? get supabaseClientOrNull {
  if (!_supabaseInitialized) return null;
  return Supabase.instance.client;
}

final supabaseClientProvider = Provider<SupabaseClient?>(
  (_) => supabaseClientOrNull,
);
