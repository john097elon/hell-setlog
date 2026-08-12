import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../remote/reaction_counts.dart';
import '../remote/row_parse.dart';
import 'author_profiles.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_comment.dart';
import '../../domain/entities/post_reaction.dart';
import '../../domain/repositories/post_repository.dart';

/// Supabase-backed public post repository. It is safe to use in local mode.
class SupabasePostRepository implements PostRepository {
  SupabasePostRepository(this._client, {this._uuid = const Uuid()});

  static const String _mediaBucket = 'post-media';

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
      final userId = client.auth.currentUser?.id;
      final blockedIds = userId == null
          ? <String>{}
          : await _blockedIds(client, userId);
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
          .where((post) => !blockedIds.contains(post.userId))
          .toList(growable: false);
      final authors = await authorProfiles(
        client,
        posts.map((post) => post.userId),
      );
      final counts = await fetchReactionCounts(
        client,
        posts.map((post) => post.id).toList(growable: false),
        viewerId: userId,
      );
      return Ok(
        posts
            .map(
              (post) => post.copyWith(
                authorName: authors[post.userId]?.nickname,
                authorAvatarUrl: authors[post.userId]?.avatarUrl,
                likeCount: counts.likes[post.id] ?? 0,
                commentCount: counts.comments[post.id] ?? 0,
                likedByMe: counts.likedByMe.contains(post.id),
                savedByMe: counts.savedByMe.contains(post.id),
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
    required String caption,
    File? media,
    bool isVideo = false,
    String? bodyPart,
    String? sessionId,
    double? volumeKg,
    int? durationMin,
    String? prLabel,
    int? xp,
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    if (userId == null) return const Err(DatabaseFailure('로그인이 필요합니다'));
    try {
      // 미디어 없이도 기록만 공유할 수 있어야 한다.
      var mediaUrl = '';
      if (media != null) {
        final extension = path.extension(media.path).replaceFirst('.', '');
        final fileName =
            '${_uuid.v4()}.${extension.isEmpty ? 'jpg' : extension}';
        final storagePath = '$userId/$fileName';
        await client.storage.from(_mediaBucket).upload(storagePath, media);
        mediaUrl = client.storage.from(_mediaBucket).getPublicUrl(storagePath);
      }
      final row = Map<String, Object?>.from(
        await client
                .from('posts')
                .insert({
                  'user_id': userId,
                  'caption': caption,
                  'media_url': mediaUrl,
                  'media_kind': isVideo ? 'video' : 'photo',
                  'body_part': bodyPart,
                  'session_id': sessionId,
                  'volume_kg': volumeKg,
                  'duration_min': durationMin,
                  'pr_label': prLabel,
                  'xp': xp,
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

  @override
  Future<Result<void, Failure>> toggleSave(String postId) =>
      _toggle('post_saves', 'post_id', postId);

  @override
  Future<Result<void, Failure>> toggleFollow(String userId) =>
      _toggle('follows', 'following_id', userId, ownerKey: 'follower_id');

  Future<Result<void, Failure>> _toggle(
    String table,
    String key,
    String value, {
    String ownerKey = 'user_id',
  }) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다'));
    }
    try {
      final row = await client
          .from(table)
          .select(key)
          .eq(key, value)
          .eq(ownerKey, userId)
          .maybeSingle();
      if (row == null) {
        await client.from(table).insert({key: value, ownerKey: userId});
      } else {
        await client.from(table).delete().eq(key, value).eq(ownerKey, userId);
      }
      return const Ok(null);
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<bool, Failure>> isFollowing(String userId) async {
    final client = _client;
    final me = client?.auth.currentUser?.id;
    if (client == null || me == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다'));
    }
    try {
      return Ok(
        await client
                .from('follows')
                .select('following_id')
                .eq('follower_id', me)
                .eq('following_id', userId)
                .maybeSingle() !=
            null,
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<void, Failure>> deletePost(String postId) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다.'));
    }
    try {
      final post = await client
          .from('posts')
          .select('id, media_url')
          .eq('id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      if (post == null) {
        return const Err(NotFoundFailure('삭제할 수 없는 게시물입니다.'));
      }
      await client
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', userId);
      // 행만 지우면 공개 URL로 사진이 계속 열린다. 저장소 파일도 함께 지운다.
      final storagePath = _storagePathOf(
        rowString(Map<String, Object?>.from(post), 'media_url'),
      );
      if (storagePath != null) {
        try {
          await client.storage.from(_mediaBucket).remove(<String>[storagePath]);
        } on Exception {
          // 파일 정리 실패가 삭제 자체를 되돌리지는 않는다.
        }
      }
      return const Ok(null);
    } on Exception catch (error) {
      return Err(DatabaseFailure('게시물을 삭제하지 못했습니다. $error'));
    }
  }

  @override
  Future<Result<void, Failure>> reportPost(String postId, String reason) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다.'));
    }
    if (reason.trim().isEmpty) {
      return const Err(DatabaseFailure('신고 사유를 선택해 주세요.'));
    }
    try {
      await client.from('post_reports').insert({
        'post_id': postId,
        'reporter_id': userId,
        'reason': reason.trim(),
      });
      return const Ok(null);
    } on Exception catch (error) {
      return Err(DatabaseFailure('신고를 접수하지 못했습니다. $error'));
    }
  }

  @override
  Future<Result<void, Failure>> blockUser(String userId) async {
    final client = _client;
    final blockerId = client?.auth.currentUser?.id;
    if (client == null || blockerId == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다.'));
    }
    if (blockerId == userId) {
      return const Err(DatabaseFailure('본인은 차단할 수 없습니다.'));
    }
    try {
      await client.from('user_blocks').upsert({
        'blocker_id': blockerId,
        'blocked_id': userId,
      });
      return const Ok(null);
    } on Exception catch (error) {
      return Err(DatabaseFailure('사용자를 차단하지 못했습니다. $error'));
    }
  }

  @override
  Future<Result<List<PostComment>, Failure>> fetchComments(
    String postId,
  ) async {
    final client = _client;
    if (client == null) return const Ok(<PostComment>[]);
    try {
      final rows = rowList(
        await client
            .from('post_comments')
            .select()
            .eq('post_id', postId)
            .order('created_at'),
      );
      // 누가 남긴 댓글인지 보이도록 작성자 프로필을 함께 읽는다.
      final authors = await authorProfiles(
        client,
        rows.map((row) => rowString(row, 'user_id')),
      );
      return Ok(
        rows
            .map((row) {
              final userId = rowString(row, 'user_id');
              final author = authors[userId];
              return PostComment(
                id: rowString(row, 'id'),
                postId: postId,
                userId: userId,
                body: rowString(row, 'body'),
                createdAt: rowDate(row, 'created_at'),
                authorName: author?.nickname,
                authorAvatarUrl: author?.avatarUrl,
              );
            })
            .toList(growable: false),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<Post, Failure>> fetchPost(String postId) async {
    final client = _client;
    if (client == null) {
      return const Err(DatabaseFailure('Supabase가 구성되지 않았습니다'));
    }
    try {
      final row = await client
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();
      if (row == null) return const Err(NotFoundFailure('게시물을 찾을 수 없습니다'));
      final post = _post(Map<String, Object?>.from(row));
      final authors = await authorProfiles(client, <String>[post.userId]);
      final counts = await fetchReactionCounts(client, <String>[
        post.id,
      ], viewerId: client.auth.currentUser?.id);
      return Ok(
        post.copyWith(
          authorName: authors[post.userId]?.nickname,
          authorAvatarUrl: authors[post.userId]?.avatarUrl,
          likeCount: counts.likes[post.id] ?? 0,
          commentCount: counts.comments[post.id] ?? 0,
          likedByMe: counts.likedByMe.contains(post.id),
          savedByMe: counts.savedByMe.contains(post.id),
        ),
      );
    } on Exception catch (error) {
      return Err(DatabaseFailure('게시물을 불러오지 못했습니다: $error'));
    }
  }

  @override
  Future<Result<List<PostReaction>, Failure>> fetchLikers(String postId) async {
    final client = _client;
    if (client == null) return const Ok(<PostReaction>[]);
    try {
      final rows = rowList(
        await client
            .from('post_likes')
            .select()
            .eq('post_id', postId)
            .order('created_at', ascending: false),
      );
      final authors = await authorProfiles(
        client,
        rows.map((row) => rowString(row, 'user_id')),
      );
      return Ok(
        rows
            .map((row) {
              final userId = rowString(row, 'user_id');
              final author = authors[userId];
              return PostReaction(
                userId: userId,
                nickname: author?.nickname ?? '회원',
                avatarUrl: author?.avatarUrl,
                createdAt: rowDate(row, 'created_at'),
              );
            })
            .toList(growable: false),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('좋아요를 불러오지 못했습니다: $e'));
    }
  }

  @override
  Future<Result<PostComment, Failure>> addComment(
    String postId,
    String body,
  ) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const Err(DatabaseFailure('로그인이 필요합니다'));
    }
    try {
      final r = Map<String, Object?>.from(
        await client
                .from('post_comments')
                .insert({'post_id': postId, 'user_id': userId, 'body': body})
                .select()
                .single()
            as Map,
      );
      return Ok(
        PostComment(
          id: r['id'] as String,
          postId: postId,
          userId: userId,
          body: body,
          createdAt: rowDate(r, 'created_at'),
        ),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  static Future<Set<String>> _blockedIds(
    SupabaseClient client,
    String userId,
  ) async {
    final rows = await client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', userId);
    return {
      for (final row in rows as List) (row as Map)['blocked_id'] as String,
    };
  }

  /// 공개 URL에서 버킷 뒤의 저장 경로만 떼어낸다. 다른 형식이면 건드리지 않는다.
  static String? _storagePathOf(String publicUrl) {
    if (publicUrl.isEmpty) return null;
    final marker = '/$_mediaBucket/';
    final index = publicUrl.indexOf(marker);
    if (index < 0) return null;
    final path = Uri.decodeComponent(
      publicUrl.substring(index + marker.length).split('?').first,
    );
    return path.isEmpty ? null : path;
  }

  static Post _post(Map<String, Object?> row) => Post(
    id: rowString(row, 'id'),
    userId: rowString(row, 'user_id'),
    caption: rowString(row, 'caption'),
    mediaUrl: rowString(row, 'media_url'),
    mediaKind: row['media_kind'] == 'video'
        ? PostMediaKind.video
        : PostMediaKind.photo,
    bodyPart: rowStringOrNull(row, 'body_part'),
    location: rowStringOrNull(row, 'location'),
    sessionId: rowStringOrNull(row, 'session_id'),
    volumeKg: rowDouble(row, 'volume_kg'),
    durationMin: rowInt(row, 'duration_min'),
    prLabel: rowStringOrNull(row, 'pr_label'),
    xp: rowInt(row, 'xp'),
    createdAt: rowDate(row, 'created_at'),
  );
}
