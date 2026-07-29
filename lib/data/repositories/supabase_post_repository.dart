import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';

/// Supabase-backed public post repository. It is safe to use in local mode.
class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client, {this._uuid = const Uuid()});

  final SupabaseClient? _client;
  final Uuid _uuid;

  @override
  Future<Result<List<Post>, Failure>> fetchPublicFeed({
    String? bodyPart,
    int limit = 20,
  }) async {
    final client = _client;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    try {
      final rows = bodyPart == null
          ? await client
                .from('posts')
                .select()
                .order('created_at', ascending: false)
                .limit(limit)
          : await client
                .from('posts')
                .select()
                .eq('body_part', bodyPart)
                .order('created_at', ascending: false)
                .limit(limit);
      final posts = (rows as List)
          .map((row) => _post(Map<String, Object?>.from(row as Map)))
          .toList(growable: false);
      final names = await _authorNames(
        client,
        posts.map((post) => post.userId),
      );
      return Ok(
        posts
            .map(
              (post) => Post(
                id: post.id,
                userId: post.userId,
                caption: post.caption,
                mediaUrl: post.mediaUrl,
                mediaKind: post.mediaKind,
                createdAt: post.createdAt,
                bodyPart: post.bodyPart,
                location: post.location,
                sessionId: post.sessionId,
                volumeKg: post.volumeKg,
                durationMin: post.durationMin,
                prLabel: post.prLabel,
                xp: post.xp,
                authorName: names[post.userId],
              ),
            )
            .toList(growable: false),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure('피드를 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<Post, Failure>> createPost({
    required File media,
    required bool isVideo,
    required String caption,
    String? bodyPart,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (userId == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      final extension = path.extension(media.path).replaceFirst('.', '');
      final fileName = '${_uuid.v4()}.${extension.isEmpty ? 'jpg' : extension}';
      final storagePath = '$userId/$fileName';
      await client.storage.from('post-media').upload(storagePath, media);
      final mediaUrl = client.storage
          .from('post-media')
          .getPublicUrl(storagePath);
      final row = Map<String, Object?>.from(
        await client
                .from('posts')
                .insert({
                  'user_id': userId,
                  'caption': caption,
                  'media_url': mediaUrl,
                  'media_kind': isVideo ? 'video' : 'photo',
                  'body_part': bodyPart,
                })
                .select()
                .single()
            as Map,
      );
      return Ok(_post(row));
    } on Exception catch (error) {
      return Err(DatabaseFailure('게시물을 저장하지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<void, Failure>> toggleLike(String postId) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (userId == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      final existing = await client
          .from('post_likes')
          .select('post_id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) {
        await client.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      } else {
        await client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      }
      return const Ok(null);
    } on Exception catch (error) {
      return Err(DatabaseFailure('좋아요를 변경하지 못했습니다: $error'));
    }
  }

  static Future<Map<String, String>> _authorNames(
    SupabaseClient client,
    Iterable<String> userIds,
  ) async {
    final ids = userIds.toSet();
    if (ids.isEmpty) return <String, String>{};
    final rows = await client
        .from('profiles')
        .select('user_id, nickname')
        .inFilter('user_id', ids.toList());
    return {
      for (final row in rows as List)
        (row as Map)['user_id'] as String:
            ((row['nickname'] as String?)?.trim().isNotEmpty ?? false)
            ? row['nickname'] as String
            : '회원',
    };
  }

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
