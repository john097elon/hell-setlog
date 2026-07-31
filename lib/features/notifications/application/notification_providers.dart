import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../data/remote/row_parse.dart';
import '../../../domain/entities/app_notification.dart';

/// 내 알림 목록. 미구성/미로그인이면 빈 목록(크래시 금지).
final myNotificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client?.auth.currentUser?.id;
  if (client == null || userId == null) return const <AppNotification>[];
  try {
    final rows = rowList(
      await client
          .from('notifications')
          .select('id, kind, body, read_at, created_at, actor_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50),
    );
    // actor_id는 auth.users를 가리켜 profiles로 조인되지 않는다. 따로 읽는다.
    final actors = await _actorProfiles(
      client,
      rows.map((row) => rowString(row, 'actor_id')),
    );
    return rows
        .map((row) => _fromRow(row, actors[rowString(row, 'actor_id')]))
        .toList(growable: false);
  } on Object {
    return const <AppNotification>[];
  }
});

/// 안 읽은 알림 수. 홈 상단 배지에 쓴다.
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final items = await ref.watch(myNotificationsProvider.future);
  return items.where((item) => item.isUnread).length;
});

/// 목록을 열었을 때 전부 읽음 처리한다. 실패해도 화면은 그대로 둔다.
Future<void> markAllNotificationsRead(WidgetRef ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = client?.auth.currentUser?.id;
  if (client == null || userId == null) return;
  try {
    await client
        .from('notifications')
        .update(<String, Object?>{'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
    ref.invalidate(myNotificationsProvider);
  } on Object {
    // 읽음 처리 실패는 조용히 넘긴다.
  }
}

Future<Map<String, ({String nickname, String? avatarUrl})>> _actorProfiles(
  SupabaseClient client,
  Iterable<String> actorIds,
) async {
  final ids = actorIds.where((id) => id.isNotEmpty).toSet();
  if (ids.isEmpty) return <String, ({String nickname, String? avatarUrl})>{};
  final rows = rowList(
    await client
        .from('profiles')
        .select('user_id, nickname, avatar_url')
        .inFilter('user_id', ids.toList()),
  );
  return <String, ({String nickname, String? avatarUrl})>{
    for (final row in rows)
      rowString(row, 'user_id'): (
        nickname: rowString(row, 'nickname', fallback: '회원'),
        avatarUrl: rowStringOrNull(row, 'avatar_url'),
      ),
  };
}

AppNotification _fromRow(
  Map<String, Object?> row,
  ({String nickname, String? avatarUrl})? actor,
) => AppNotification(
  id: rowString(row, 'id'),
  kind: notificationKindFrom(rowStringOrNull(row, 'kind')),
  body: rowStringOrNull(row, 'body'),
  actorName: actor?.nickname,
  actorAvatarUrl: actor?.avatarUrl,
  readAt: rowDateOrNull(row, 'read_at'),
  createdAt: rowDate(row, 'created_at'),
);
