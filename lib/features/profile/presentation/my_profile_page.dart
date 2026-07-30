import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_states.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/application/auth_service.dart';
import '../application/profile_providers.dart';

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
    if (saved != true || !mounted) return;
    final result = await ref
        .read(profileRepositoryProvider)
        .updateProfile(nickname: nickname.text.trim(), bio: bio.text.trim());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: <Widget>[
          IconButton(
            tooltip: '설정',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const AppLoading(),
        error: (_, _) => const _LoginRequired(),
        data: (value) => _ProfileBody(
          profile: value,
          isUploadingAvatar: _isUploadingAvatar,
          onAvatarTap: _pickAvatar,
          onEdit: () => _editProfile(value),
        ),
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
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: <Widget>[
                _Avatar(
                  profile: profile,
                  loading: isUploadingAvatar,
                  onTap: onAvatarTap,
                ),
                const SizedBox(height: 14),
                Text(
                  profile.nickname,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (profile.bio?.isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    profile.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.tokens.mutedText),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('프로필 편집'),
                ),
                const SizedBox(height: 12),
                _Stats(
                  posts: posts.valueOrNull?.length ?? 0,
                  followers: follows.followers,
                  following: follows.following,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '내 게시물',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
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
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PostThumbnail(post: values[index]),
                      childCount: values.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
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
        borderRadius: BorderRadius.circular(48),
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
                      profile.nickname.characters.first,
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

class _Stats extends StatelessWidget {
  const _Stats({
    required this.posts,
    required this.followers,
    required this.following,
  });
  final int posts;
  final int followers;
  final int following;
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _Stat(label: '게시물', value: posts),
      _Stat(label: '팔로워', value: followers),
      _Stat(label: '팔로잉', value: following),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: <Widget>[
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: context.tokens.mutedText)),
      ],
    ),
  );
}

/// 그리드 한 칸. 사진은 이미지로, 영상과 기록 전용 글은 대체 표시로 보여준다.
class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({required this.post});

  final Post post;

  bool get _isVideo => post.mediaKind == PostMediaKind.video;
  bool get _hasMedia => post.mediaUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bg,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (_hasMedia && !_isVideo)
              Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(t),
              )
            else
              _fallback(t),
            if (_isVideo)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 18,
                    color: t.text.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 미디어를 못 그릴 때도 무엇을 올린 글인지 알 수 있게 요약을 보여준다.
  Widget _fallback(AppTokens t) => Padding(
    padding: const EdgeInsets.all(6),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          _isVideo ? Icons.videocam_outlined : Icons.article_outlined,
          size: 20,
          color: t.faintText,
        ),
        const SizedBox(height: 4),
        Text(
          post.volumeKg != null
              ? '${post.volumeKg!.round()} kg'
              : (post.caption.isEmpty ? '기록' : post.caption),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: t.mutedText,
          ),
        ),
      ],
    ),
  );
}

class _LoginRequired extends StatelessWidget {
  const _LoginRequired();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('프로필')),
    body: AppEmptyState(
      icon: Icons.person_outline,
      title: '로그인이 필요합니다',
      action: FilledButton(
        onPressed: () => context.go('/login'),
        child: const Text('로그인'),
      ),
    ),
  );
}
