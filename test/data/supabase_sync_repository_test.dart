import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/repositories/supabase_sync_repository.dart';

void main() {
  test('does nothing without a Supabase client', () async {
    const repository = SupabaseSyncRepository(null);

    await repository.pushAll();
    await repository.pullAll();
  });
}
