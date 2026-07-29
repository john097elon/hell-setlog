import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../domain/entities/app_notification.dart';

/// 내 알림 목록. 미구성/미로그인이면 빈 목록(크래시 금지).
final myNotificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client?.auth.currentUser?.id;
  if (client == null || userId == null) return const <AppNotification>[];
  try {
    final rows = await client
        .from('notifications')
        .select(
          'id, kind, body, read_at, created_at, actor:actor_id(nickname, avatar_url)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(_fromRow).toList(growable: false);
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

AppNotification _fromRow(Map<String, dynamic> row) {
  final actor = row['actor'];
  final actorMap = actor is Map<String, dynamic> ? actor : null;
  return AppNotification(
    id: row['id'] as String,
    kind: notificationKindFrom(row['kind'] as String?),
    body: row['body'] as String?,
    actorName: actorMap?['nickname'] as String?,
    actorAvatarUrl: actorMap?['avatar_url'] as String?,
    readAt: DateTime.tryParse((row['read_at'] as String?) ?? ''),
    createdAt:
        DateTime.tryParse((row['created_at'] as String?) ?? '') ??
        DateTime.now(),
  );
}
