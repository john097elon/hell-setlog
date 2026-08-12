import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/row_parse.dart';

typedef AuthorProfile = ({String nickname, String? avatarUrl});

/// 글쓴이 표시에 필요한 프로필만 모아 온다.
///
/// 피드마다 따로 구현하다 보니 파티 피드에는 아예 빠져 있었고, 파티원의 글이
/// 전부 "파티원"으로 보였다.
Future<Map<String, AuthorProfile>> authorProfiles(
  SupabaseClient client,
  Iterable<String> userIds,
) async {
  final ids = userIds.where((id) => id.isNotEmpty).toSet();
  if (ids.isEmpty) return const <String, AuthorProfile>{};
  final rows = rowList(
    await client
        .from('profiles')
        .select('user_id, nickname, avatar_url')
        .inFilter('user_id', ids.toList()),
  );
  return <String, AuthorProfile>{
    for (final row in rows)
      rowString(row, 'user_id'): (
        nickname: rowString(row, 'nickname', fallback: '회원'),
        avatarUrl: rowStringOrNull(row, 'avatar_url'),
      ),
  };
}
