import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/app_notification.dart';
import '../application/notification_providers.dart';
import '../../../core/formatting/app_format.dart';
import '../../profile/presentation/user_profile_page.dart';
import '../../feed/presentation/post_detail_page.dart';

/// 좋아요·댓글·팔로우·파티 참여 알림을 모아 보여준다.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _markedRead = false;

  /// 목록을 성공적으로 보여준 뒤에만 읽음으로 처리한다. 조회가 실패했는데
  /// 읽음만 성공하면 사용자는 보지도 못한 알림을 잃는다.
  void _markReadOnce() {
    if (_markedRead) return;
    _markedRead = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => markAllNotificationsRead(ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: '알림',
      slivers: ref
          .watch(myNotificationsProvider)
          .when(
            loading: () => const <Widget>[
              SliverFillRemaining(child: AppLoading()),
            ],
            error: (_, _) => const <Widget>[
              SliverFillRemaining(
                child: AppEmptyState(
                  icon: Icons.error_outline,
                  title: '알림을 불러오지 못했습니다',
                ),
              ),
            ],
            data: (items) {
              _markReadOnce();
              return items.isEmpty
                  ? const <Widget>[
                      SliverFillRemaining(
                        child: AppEmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: '알림이 없습니다',
                          message: '파티원과 소통하면 알림이 도착합니다.',
                        ),
                      ),
                    ]
                  : <Widget>[
                      SliverToBoxAdapter(
                        child: AppPagePadding(
                          top: AppSpacing.md,
                          child: AppSection(
                            children: <Widget>[
                              for (final item in items)
                                _NotificationTile(item: item),
                            ],
                          ),
                        ),
                      ),
                    ];
            },
          ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  /// 좋아요·댓글은 그 게시물로, 팔로우는 그 사람 프로필로 간다.
  void _open(BuildContext context) {
    final postId = item.postId;
    if (postId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PostDetailRoute(postId: postId),
        ),
      );
      return;
    }
    final actorId = item.actorId;
    if (actorId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserProfilePage(userId: actorId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // 닉네임이 빈 문자열로 오면 characters.first가 던지므로 여기서 막는다.
    final name = item.actorName?.trim() ?? '';
    final actor = name.isEmpty ? '회원' : name;
    final avatar = item.actorAvatarUrl;
    return AppRow(
      onTap: () => _open(context),
      leading: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.bg,
          shape: BoxShape.circle,
          border: Border.all(color: item.isUnread ? t.brand : t.border),
        ),
        child: (avatar ?? '').isEmpty
            ? Text(
                initialOf(actor),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              )
            : Image.network(
                avatar!,
                width: 26,
                height: 26,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(Icons.person_outline, color: t.faintText, size: 18),
              ),
      ),
      title: '$actor님이 ${_message(item.kind)}',
      value: _relativeTime(item.createdAt),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (item.isUnread) ...<Widget>[
            Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(color: t.brand, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Icon(Icons.chevron_right_rounded, size: 20, color: t.faintText),
        ],
      ),
    );
  }

  String _message(NotificationKind kind) => switch (kind) {
    NotificationKind.like => '회원님의 게시물을 좋아합니다.',
    NotificationKind.comment => '댓글을 남겼습니다.',
    NotificationKind.follow => '회원님을 팔로우합니다.',
    NotificationKind.partyJoin => '파티에 참여했습니다.',
    NotificationKind.evolution => '캐릭터가 진화했습니다.',
    NotificationKind.unknown => '활동을 남겼습니다.',
  };

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}월 ${time.day}일';
  }
}
