import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/config/app_env.dart';

void main() {
  test('Supabase is unconfigured without dart defines', () {
    expect(isSupabaseConfigured, isFalse);
  });
}
