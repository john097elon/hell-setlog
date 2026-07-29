import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/data/repositories/supabase_post_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'returns Failure instead of throwing when Supabase is unavailable',
    () async {
      final repository = SupabasePostRepository(null);

      expect((await repository.fetchPublicFeed()).isOk, isFalse);
      expect(
        (await repository.createPost(
          media: File('post.jpg'),
          isVideo: false,
          caption: 'caption',
        )).isOk,
        isFalse,
      );
      expect((await repository.toggleLike('post-id')).isOk, isFalse);
    },
  );

  test(
    'returns Failure instead of throwing when no user is signed in',
    () async {
      final repository = SupabasePostRepository(
        SupabaseClient('https://example.com', 'test-anon-key'),
      );

      expect(
        (await repository.createPost(
          media: File('post.jpg'),
          isVideo: false,
          caption: 'caption',
        )).isOk,
        isFalse,
      );
      expect((await repository.toggleLike('post-id')).isOk, isFalse);
    },
  );
}
