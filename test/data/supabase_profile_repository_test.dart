import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/repositories/supabase_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('returns Failure without Supabase configuration', () async {
    final repository = SupabaseProfileRepository(null);

    expect((await repository.fetchMyProfile()).isOk, isFalse);
    expect((await repository.updateProfile(nickname: '회원')).isOk, isFalse);
    expect((await repository.uploadAvatar(File('avatar.jpg'))).isOk, isFalse);
    expect((await repository.fetchMyPosts()).isOk, isFalse);
  });

  test('returns Failure without a signed-in user', () async {
    final repository = SupabaseProfileRepository(
      SupabaseClient('https://example.com', 'test-anon-key'),
    );

    expect((await repository.fetchMyProfile()).isOk, isFalse);
    expect((await repository.fetchMyPosts()).isOk, isFalse);
  });
}
