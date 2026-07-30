import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
      final nickname = user.email?.split('@').first ?? '회원';
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
      return Ok(
        (rows as List)
            .map((row) => _post(Map<String, Object?>.from(row as Map)))
            .toList(growable: false),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure('내 게시물을 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<({int followers, int following}), Failure>>
  fetchFollowCounts() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null)
      return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      final rows = await Future.wait<List>(<Future<List>>[
        client.from('follows').select('follower_id').eq('following_id', userId),
        client.from('follows').select('following_id').eq('follower_id', userId),
      ]);
      return Ok((followers: rows[0].length, following: rows[1].length));
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  static UserProfile _profile(Map<String, Object?> row) => UserProfile(
    userId: row['user_id'] as String,
    nickname: row['nickname'] as String? ?? '회원',
    avatarUrl: row['avatar_url'] as String?,
    bio: row['bio'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  static Post _post(Map<String, Object?> row) => Post(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    caption: row['caption'] as String? ?? '',
    mediaUrl: row['media_url'] as String,
    mediaKind: row['media_kind'] == 'video'
        ? PostMediaKind.video
        : PostMediaKind.photo,
    bodyPart: row['body_part'] as String?,
    location: row['location'] as String?,
    sessionId: row['session_id'] as String?,
    volumeKg: (row['volume_kg'] as num?)?.toDouble(),
    durationMin: (row['duration_min'] as num?)?.toInt(),
    prLabel: row['pr_label'] as String?,
    xp: (row['xp'] as num?)?.toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
