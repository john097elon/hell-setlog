import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_init.dart';

/// 검색 결과에 필요한 최소 사용자 정보.
class SearchedUser {
  const SearchedUser({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
  });

  final String userId;
  final String nickname;
  final String? avatarUrl;
}

/// 닉네임으로 사용자를 찾는다. 미구성이면 빈 목록을 준다(크래시 금지).
final userSearchProvider = FutureProvider.family<List<SearchedUser>, String>((
  ref,
  query,
) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const <SearchedUser>[];
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const <SearchedUser>[];
  try {
    final rows = await client
        .from('profiles')
        .select('user_id, nickname, avatar_url')
        .ilike('nickname', '%$trimmed%')
        .limit(20);
    return rows
        .map(
          (row) => SearchedUser(
            userId: row['user_id'] as String,
            nickname: (row['nickname'] as String?) ?? '회원',
            avatarUrl: row['avatar_url'] as String?,
          ),
        )
        .toList(growable: false);
  } on Object {
    return const <SearchedUser>[];
  }
});
