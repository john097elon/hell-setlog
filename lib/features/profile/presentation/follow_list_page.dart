import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/application/auth_service.dart';
import '../application/profile_providers.dart';
import 'user_profile_page.dart';

/// 팔로워 또는 팔로잉 목록.
class FollowListPage extends ConsumerWidget {
  const FollowListPage({
    required this.userId,
    required this.followers,
    this.title,
    super.key,
  });

  final String userId;
  final bool followers;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(
      followListProvider((userId: userId, followers: followers)),
    );
    final label = followers ? '팔로워' : '팔로잉';
    return AppScreen(
      title: title == null ? label : '${title!}의 $label',
      slivers: people.when(
        loading: () => const <Widget>[SliverFillRemaining(child: AppLoading())],
        error: (_, _) => <Widget>[
          SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.error_outline,
              title: '$label 목록을 불러오지 못했습니다',
            ),
          ),
        ],
        data: (items) => items.isEmpty
            ? <Widget>[
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.person_outline,
                    title: followers ? '아직 팔로워가 없습니다' : '아직 팔로우한 사람이 없습니다',
                  ),
                ),
              ]
            : <Widget>[
                SliverToBoxAdapter(
                  child: AppPagePadding(
                    top: AppSpacing.md,
                    child: AppSection(
                      children: <Widget>[
                        for (final item in items) _PersonTile(profile: item),
                      ],
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final url = profile.avatarUrl ?? '';
    final isMe = ref.watch(authServiceProvider).currentUserId == profile.userId;
    return AppRow(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserProfilePage(userId: profile.userId),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: t.bg,
        backgroundImage: url.isEmpty ? null : NetworkImage(url),
        child: url.isEmpty
            ? Text(
                initialOf(profile.nickname),
                style: TextStyle(fontWeight: FontWeight.w700, color: t.text),
              )
            : null,
      ),
      title: profile.nickname,
      subtitle: (profile.bio?.isNotEmpty ?? false) ? profile.bio! : null,
      trailing: isMe
          ? null
          : FollowButton(userId: profile.userId, compact: true),
    );
  }
}
