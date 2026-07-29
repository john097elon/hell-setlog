/// 알림 종류. 문구는 화면에서 종류에 맞춰 만든다.
enum NotificationKind { like, comment, follow, partyJoin, unknown }

/// 사용자에게 도착한 알림 한 건.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.actorName,
    this.actorAvatarUrl,
    this.body,
    this.readAt,
  });

  final String id;
  final NotificationKind kind;
  final DateTime createdAt;
  final String? actorName;
  final String? actorAvatarUrl;
  final String? body;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}

/// 서버가 준 문자열을 알림 종류로 바꾼다.
NotificationKind notificationKindFrom(String? raw) => switch (raw) {
  'like' => NotificationKind.like,
  'comment' => NotificationKind.comment,
  'follow' => NotificationKind.follow,
  'party_join' => NotificationKind.partyJoin,
  _ => NotificationKind.unknown,
};
