import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/app_format.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/application/auth_service.dart';
import '../../feed/application/post_providers.dart';
import '../../feed/presentation/post_detail_page.dart';
import '../application/profile_providers.dart';
import 'follow_list_page.dart';
import 'widgets/post_grid.dart';

/// 다른 사용자의 공개 프로필. 팔로우와 게시물 목록을 제공한다.
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(userId));
    return profile.when(
      loading: () => const AppScreen(
        title: '프로필',
        slivers: <Widget>[SliverFillRemaining(child: AppLoading())],
      ),
      error: (_, _) => const AppScreen(
        title: '프로필',
        slivers: <Widget>[
          SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.person_off_outlined,
              title: '프로필을 불러오지 못했습니다',
            ),
          ),
        ],
      ),
      data: (value) => _Body(profile: value),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final posts = ref.watch(userPostsProvider(profile.userId));
    final counts =
        ref.watch(followCountsProvider(profile.userId)).valueOrNull ??
        (followers: 0, following: 0);
    final isMe = ref.watch(authServiceProvider).currentUserId == profile.userId;
    return AppScreen(
      title: profile.nickname,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: AppPagePadding(
            top: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _Avatar(profile: profile),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          _CountTile(
                            label: '게시물',
                            value: posts.valueOrNull?.length ?? 0,
                          ),
                          _CountTile(
                            label: '팔로워',
                            value: counts.followers,
                            onTap: () =>
                                _openFollowList(context, followers: true),
                          ),
                          _CountTile(
                            label: '팔로잉',
                            value: counts.following,
                            onTap: () =>
                                _openFollowList(context, followers: false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  profile.nickname,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.bio?.isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(profile.bio!, style: TextStyle(color: t.mutedText)),
                ],
                if (!isMe) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  FollowButton(userId: profile.userId),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('게시물', style: AppText.sectionLabel(context)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        posts.when(
          loading: () => const SliverFillRemaining(child: AppLoading()),
          error: (_, _) => const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.error_outline,
              title: '게시물을 불러오지 못했습니다',
            ),
          ),
          data: (values) => values.isEmpty
              ? const SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.photo_outlined,
                    title: '게시물이 없습니다',
                  ),
                )
              : PostGridSliver(
                  posts: values,
                  onTap: (post) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PostDetailPage(post: post),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _openFollowList(BuildContext context, {required bool followers}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FollowListPage(
            userId: profile.userId,
            followers: followers,
            title: profile.nickname,
          ),
        ),
      );
}

/// 팔로우 상태를 낙관적으로 토글한다.
class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({required this.userId, this.compact = false, super.key});

  final String userId;
  final bool compact;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool? _override;
  bool _busy = false;

  Future<void> _toggle(bool current) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _override = !current;
    });
    final result = await ref
        .read(postRepositoryProvider)
        .toggleFollow(widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (_) {
        ref
          ..invalidate(isFollowingProvider(widget.userId))
          ..invalidate(followCountsProvider(widget.userId))
          ..invalidate(myFollowCountsProvider);
      },
      err: (failure) {
        // 실패했으면 눌리기 전 상태로 되돌린다.
        setState(() => _override = current);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final following =
        _override ??
        ref.watch(isFollowingProvider(widget.userId)).valueOrNull ??
        false;
    final label = following ? '팔로잉' : '팔로우';
    if (widget.compact) {
      return TextButton(
        onPressed: () => _toggle(following),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          minimumSize: const Size(0, 48),
          foregroundColor: following
              ? context.tokens.mutedText
              : context.tokens.brand,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: following
          ? OutlinedButton(
              onPressed: () => _toggle(following),
              child: Text(label),
            )
          : FilledButton(
              onPressed: () => _toggle(following),
              child: Text(label),
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = profile.avatarUrl ?? '';
    return CircleAvatar(
      radius: 40,
      backgroundColor: t.bg,
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      child: url.isEmpty
          ? Text(
              initialOf(profile.nickname),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            )
          : null,
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: <Widget>[
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontFeatures: kTabularFigures),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.tokens.mutedText),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 그리드 진입을 위해 게시물 목록을 노출한다.
typedef PostTapped = void Function(Post post);
