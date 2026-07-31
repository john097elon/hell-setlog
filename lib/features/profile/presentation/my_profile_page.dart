import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_list.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/application/auth_service.dart';
import '../../feed/presentation/post_detail_page.dart';
import '../application/profile_providers.dart';
import 'follow_list_page.dart';
import 'widgets/post_grid.dart';
import '../../../core/formatting/app_format.dart';

/// The signed-in user's profile, avatar editor, and personal post grid.
class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => _isUploadingAvatar = true);
    final result = await ref
        .read(profileRepositoryProvider)
        .uploadAvatar(File(image.path));
    if (!mounted) return;
    result.when(
      ok: (_) => ref.invalidate(myProfileProvider),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
    if (mounted) setState(() => _isUploadingAvatar = false);
  }

  Future<void> _editProfile(UserProfile profile) async {
    final nickname = TextEditingController(text: profile.nickname);
    final bio = TextEditingController(text: profile.bio ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('프로필 편집'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nickname,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            TextField(
              controller: bio,
              decoration: const InputDecoration(labelText: '소개'),
              maxLines: 2,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      nickname.dispose();
      bio.dispose();
      return;
    }
    final nextNickname = nickname.text.trim();
    final nextBio = bio.text.trim();
    nickname.dispose();
    bio.dispose();
    final result = await ref
        .read(profileRepositoryProvider)
        .updateProfile(nickname: nextNickname, bio: nextBio);
    if (!mounted) return;
    result.when(
      ok: (_) => ref.invalidate(myProfileProvider),
      err: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authServiceProvider).currentUserId;
    if (userId == null) return const _LoginRequired();
    final profile = ref.watch(myProfileProvider);
    return profile.when(
      loading: () => const AppScreen(
        title: '프로필',
        slivers: <Widget>[SliverFillRemaining(child: AppLoading())],
      ),
      error: (_, _) => const _LoginRequired(),
      data: (value) => _ProfileBody(
        profile: value,
        isUploadingAvatar: _isUploadingAvatar,
        onAvatarTap: _pickAvatar,
        onEdit: () => _editProfile(value),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
    required this.onEdit,
  });
  final UserProfile profile;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(myPostsProvider);
    final follows =
        ref.watch(myFollowCountsProvider).valueOrNull ??
        (followers: 0, following: 0);
    return AppScreen(
      title: '프로필',
      actions: <Widget>[
        IconButton(
          tooltip: '설정',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: AppPagePadding(
            top: AppSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _Avatar(
                      profile: profile,
                      loading: isUploadingAvatar,
                      onTap: onAvatarTap,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _Stats(
                        posts: posts.valueOrNull?.length ?? 0,
                        followers: follows.followers,
                        following: follows.following,
                        onFollowers: () => _openFollowList(
                          context,
                          profile.userId,
                          followers: true,
                        ),
                        onFollowing: () => _openFollowList(
                          context,
                          profile.userId,
                          followers: false,
                        ),
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
                  Text(
                    profile.bio!,
                    style: TextStyle(color: context.tokens.mutedText),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('프로필 편집'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('내 게시물', style: AppText.sectionLabel(context)),
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
                    message: '첫 게시물을 남겨보세요.',
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
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.profile,
    required this.loading,
    required this.onTap,
  });
  final UserProfile profile;
  final bool loading;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: '프로필 사진 변경',
      child: InkWell(
        onTap: loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            CircleAvatar(
              radius: 44,
              backgroundColor: t.bg,
              backgroundImage: profile.avatarUrl?.isNotEmpty == true
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: loading
                  ? const CircularProgressIndicator()
                  : profile.avatarUrl?.isNotEmpty == true
                  ? null
                  : Text(
                      initialOf(profile.nickname),
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: t.text,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.card, width: 2),
                ),
                child: Icon(Icons.camera_alt_outlined, size: 15, color: t.card),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openFollowList(
  BuildContext context,
  String userId, {
  required bool followers,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => FollowListPage(userId: userId, followers: followers),
  ),
);

class _Stats extends StatelessWidget {
  const _Stats({
    required this.posts,
    required this.followers,
    required this.following,
    this.onFollowers,
    this.onFollowing,
  });
  final int posts;
  final int followers;
  final int following;
  final VoidCallback? onFollowers;
  final VoidCallback? onFollowing;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _Stat(label: '게시물', value: posts),
      _Stat(label: '팔로워', value: followers, onTap: onFollowers),
      _Stat(label: '팔로잉', value: following, onTap: onFollowing),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.onTap});
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

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();
  @override
  Widget build(BuildContext context) => AppScreen(
    title: '프로필',
    slivers: <Widget>[
      SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.person_outline,
          title: '로그인이 필요합니다',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('로그인'),
          ),
        ),
      ),
    ],
  );
}
