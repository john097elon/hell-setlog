import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_tokens.dart';
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
    return Scaffold(
      backgroundColor: context.tokens.bg,
      appBar: AppBar(title: Text(title == null ? label : '${title!}의 $label')),
      body: people.when(
        loading: () => const AppLoading(),
        error: (_, _) => AppEmptyState(
          icon: Icons.error_outline,
          title: '$label 목록을 불러오지 못했습니다',
        ),
        data: (items) => items.isEmpty
            ? AppEmptyState(
                icon: Icons.person_outline,
                title: followers ? '아직 팔로워가 없습니다' : '아직 팔로우한 사람이 없습니다',
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _PersonTile(profile: items[index]),
              ),
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
    return ListTile(
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
      title: Text(
        profile.nickname,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (profile.bio?.isNotEmpty ?? false)
          ? Text(profile.bio!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: isMe
          ? null
          : FollowButton(userId: profile.userId, compact: true),
    );
  }
}
