import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../remote/reaction_counts.dart';
import '../remote/row_parse.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Supabase-backed profile repository that is safe when local mode is active.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client, {this.uuid = const Uuid()});

  final SupabaseClient? _client;
  final Uuid uuid;

  @override
  Future<Result<UserProfile, Failure>> fetchMyProfile() async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (user == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (row != null) return Ok(_profile(Map<String, Object?>.from(row)));
      // 가입 때 입력한 닉네임을 우선 쓰고, 없을 때만 이메일 앞부분으로 채운다.
      final signUpNickname = (user.userMetadata?['nickname'] as String?)
          ?.trim();
      final nickname = (signUpNickname?.isNotEmpty ?? false)
          ? signUpNickname!
          : (user.email?.split('@').first ?? '회원');
      final created = await client
          .from('profiles')
          .upsert({'user_id': user.id, 'nickname': nickname})
          .select()
          .single();
      return Ok(_profile(Map<String, Object?>.from(created as Map)));
    } on Exception catch (error) {
      return Err(DatabaseFailure('프로필을 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<UserProfile, Failure>> updateProfile({
    String? nickname,
    String? bio,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (userId == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    if (nickname == null && bio == null) return fetchMyProfile();
    try {
      final values = <String, Object?>{};
      if (nickname != null) values['nickname'] = nickname;
      if (bio != null) values['bio'] = bio;
      final row = await client
          .from('profiles')
          .update(values)
          .eq('user_id', userId)
          .select()
          .maybeSingle();
      if (row != null) return Ok(_profile(Map<String, Object?>.from(row)));
      final current = await fetchMyProfile();
      return current.when(
        ok: (profile) async {
          final created = await client
              .from('profiles')
              .upsert({
                'user_id': userId,
                'nickname': nickname ?? profile.nickname,
                'bio': bio ?? profile.bio,
              })
              .select()
              .single();
          return Ok(_profile(Map<String, Object?>.from(created as Map)));
        },
        err: Err.new,
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure('프로필을 저장하지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<String, Failure>> uploadAvatar(File image) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (userId == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      final extension = path.extension(image.path).replaceFirst('.', '');
      final storagePath =
          '$userId/avatar/${uuid.v4()}.${extension.isEmpty ? 'jpg' : extension}';
      await client.storage
          .from('post-media')
          .upload(
            storagePath,
            image,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = client.storage.from('post-media').getPublicUrl(storagePath);
      final current = await fetchMyProfile();
      final nickname = current.when(
        ok: (profile) => profile.nickname,
        err: (_) => '회원',
      );
      await client.from('profiles').upsert({
        'user_id': userId,
        'nickname': nickname,
        'avatar_url': url,
      });
      return Ok(url);
    } on Exception catch (error) {
      return Err(DatabaseFailure('프로필 사진을 저장하지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<List<Post>, Failure>> fetchMyPosts() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (userId == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      final rows = await client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final posts = (rows as List)
          .map((row) => _post(Map<String, Object?>.from(row as Map)))
          .toList(growable: false);
      // 내 글에 누가 반응했는지 목록에서 바로 보이도록 반응 수를 채운다.
      final counts = await fetchReactionCounts(
        client,
        posts.map((post) => post.id).toList(growable: false),
        viewerId: userId,
      );
      return Ok(
        posts
            .map(
              (post) => post.copyWith(
                likeCount: counts.likes[post.id] ?? 0,
                commentCount: counts.comments[post.id] ?? 0,
              ),
            )
            .toList(growable: false),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure('내 게시물을 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<({int followers, int following}), Failure>> fetchFollowCounts([
    String? userId,
  ]) async {
    final client = _client;
    final target = userId ?? client?.auth.currentUser?.id;
    if (client == null || target == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다'));
    }
    try {
      final rows = await Future.wait<List>(<Future<List>>[
        client.from('follows').select('follower_id').eq('following_id', target),
        client.from('follows').select('following_id').eq('follower_id', target),
      ]);
      return Ok((followers: rows[0].length, following: rows[1].length));
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<UserProfile, Failure>> fetchProfile(String userId) async {
    final client = _client;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    try {
      final row = await client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return const Err(NotFoundFailure('프로필을 찾을 수 없습니다'));
      return Ok(_profile(Map<String, Object?>.from(row)));
    } on Exception catch (error) {
      return Err(DatabaseFailure('프로필을 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<List<Post>, Failure>> fetchUserPosts(String userId) async {
    final client = _client;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    try {
      final rows = await client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final posts = (rows as List)
          .map((row) => _post(Map<String, Object?>.from(row as Map)))
          .toList(growable: false);
      final counts = await fetchReactionCounts(
        client,
        posts.map((post) => post.id).toList(growable: false),
        viewerId: client.auth.currentUser?.id,
      );
      return Ok(
        posts
            .map(
              (post) => post.copyWith(
                likeCount: counts.likes[post.id] ?? 0,
                commentCount: counts.comments[post.id] ?? 0,
                likedByMe: counts.likedByMe.contains(post.id),
              ),
            )
            .toList(growable: false),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure('게시물을 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<List<UserProfile>, Failure>> fetchFollowList(
    String userId, {
    required bool followers,
  }) async {
    final client = _client;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    try {
      // 팔로워 목록이면 나를 following하는 사람들의 follower_id를 모은다.
      final rows = rowList(
        followers
            ? await client
                  .from('follows')
                  .select('follower_id')
                  .eq('following_id', userId)
            : await client
                  .from('follows')
                  .select('following_id')
                  .eq('follower_id', userId),
      );
      final ids = rows
          .map(
            (row) => rowString(row, followers ? 'follower_id' : 'following_id'),
          )
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (ids.isEmpty) return const Ok(<UserProfile>[]);
      final profiles = rowList(
        await client.from('profiles').select().inFilter('user_id', ids),
      );
      return Ok(profiles.map(_profile).toList(growable: false));
    } on Exception catch (error) {
      return Err(DatabaseFailure('목록을 불러오지 못했습니다: $error'));
    }
  }

  static UserProfile _profile(Map<String, Object?> row) => UserProfile(
    userId: row['user_id'] as String,
    nickname: row['nickname'] as String? ?? '회원',
    avatarUrl: row['avatar_url'] as String?,
    bio: row['bio'] as String?,
    createdAt: rowDate(row, 'created_at'),
  );

  static Post _post(Map<String, Object?> row) => Post(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    caption: row['caption'] as String? ?? '',
    mediaUrl: rowString(row, 'media_url'),
    mediaKind: row['media_kind'] == 'video'
        ? PostMediaKind.video
        : PostMediaKind.photo,
    bodyPart: row['body_part'] as String?,
    location: row['location'] as String?,
    sessionId: row['session_id'] as String?,
    volumeKg: rowDouble(row, 'volume_kg'),
    durationMin: rowInt(row, 'duration_min'),
    prLabel: row['pr_label'] as String?,
    xp: rowInt(row, 'xp'),
    createdAt: rowDate(row, 'created_at'),
  );
}
