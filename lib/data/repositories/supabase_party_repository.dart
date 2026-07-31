import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/row_parse.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_member.dart';
import '../../domain/entities/party_message.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/party_repository.dart';

class SupabasePartyRepository implements PartyRepository {
  const SupabasePartyRepository(this._client);
  final SupabaseClient? _client;
  String? get _userId => _client?.auth.currentUser?.id;
  Failure get _authFailure => const DatabaseFailure('로그인이 필요합니다');

  @override
  Future<Result<List<Party>, Failure>> fetchMyParties() => _parties(mine: true);
  @override
  Future<Result<List<Party>, Failure>> explore({
    String? region,
    String? focus,
  }) => _parties(region: region, focus: focus);
  Future<Result<List<Party>, Failure>> _parties({
    bool mine = false,
    String? region,
    String? focus,
  }) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      final rows = mine
          ? await c.from('party_members').select('parties(*)').eq('user_id', u)
          : await c.from('parties').select();
      final values = (rows as List)
          .map(
            (r) => Map<String, Object?>.from(
              mine ? (r as Map)['parties'] as Map : r as Map,
            ),
          )
          .where(
            (r) =>
                (region == null || r['region'] == region) &&
                (focus == null || r['focus'] == focus),
          )
          .map(_party)
          .toList();
      // 목록에 항상 0명으로 뜨던 자리. 인원수를 한 번의 질의로 모아 채운다.
      final counts = await _memberCounts(
        c,
        values.map((party) => party.id).toList(growable: false),
      );
      return Ok(
        values
            .map(
              (party) => party.copyWith(
                memberCount: counts[party.id] ?? party.memberCount,
              ),
            )
            .toList(growable: false),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<Party, Failure>> createParty({
    required String name,
    String? description,
    String? region,
    String? focus,
    required int maxMembers,
    required bool isPublic,
  }) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      final row = Map<String, Object?>.from(
        await c
                .from('parties')
                .insert({
                  'owner_id': u,
                  'name': name,
                  'description': description,
                  'region': region,
                  'focus': focus,
                  'max_members': maxMembers,
                  'is_public': isPublic,
                  'join_code': isPublic ? null : _code(),
                })
                .select()
                .single()
            as Map,
      );
      await c.from('party_members').insert({
        'party_id': row['id'],
        'user_id': u,
        'role': 'owner',
      });
      return Ok(_party(row));
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<void, Failure>> joinParty(String partyId) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      final p = Map<String, Object?>.from(
        await c.from('parties').select().eq('id', partyId).single() as Map,
      );
      final m = await c
          .from('party_members')
          .select('user_id')
          .eq('party_id', partyId);
      if ((m as List).length >= (p['max_members'] as num).toInt()) {
        return const Err(DatabaseFailure('정원이 가득 찼습니다'));
      }
      await c.from('party_members').insert({'party_id': partyId, 'user_id': u});
      return const Ok(null);
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<void, Failure>> joinByCode(String code) async {
    final c = _client;
    if (c == null || _userId == null) return Err(_authFailure);
    try {
      final p = await c
          .from('parties')
          .select('id')
          .eq('join_code', code)
          .maybeSingle();
      if (p == null) return const Err(DatabaseFailure('참여 코드를 찾을 수 없습니다'));
      return joinParty((p as Map)['id'] as String);
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<void, Failure>> leaveParty(String partyId) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      final p =
          await c.from('parties').select('owner_id').eq('id', partyId).single()
              as Map;
      if (p['owner_id'] == u) {
        return const Err(DatabaseFailure('파티장은 나갈 수 없습니다. 파티를 삭제하거나 위임하세요.'));
      }
      await c
          .from('party_members')
          .delete()
          .eq('party_id', partyId)
          .eq('user_id', u);
      return const Ok(null);
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<List<PartyMember>, Failure>> fetchMembers(
    String partyId,
  ) async {
    final c = _client;
    if (c == null || _userId == null) return Err(_authFailure);
    try {
      final rows = await c
          .from('party_members')
          .select('user_id,role,joined_at,profiles(nickname,avatar_url)')
          .eq('party_id', partyId);
      return Ok(
        rowList(rows).map((m) {
          // 조인 결과는 객체 또는 배열로 올 수 있어 둘 다 처리한다.
          final profile = rowNested(m, 'profiles');
          return PartyMember(
            userId: rowString(m, 'user_id'),
            nickname: profile == null
                ? '회원'
                : rowString(profile, 'nickname', fallback: '회원'),
            avatarUrl: profile == null
                ? null
                : rowStringOrNull(profile, 'avatar_url'),
            role: rowString(m, 'role', fallback: 'member'),
            joinedAt: rowDate(m, 'joined_at'),
          );
        }).toList(),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<List<PartyMessage>, Failure>> fetchMessages(
    String partyId, {
    int limit = 50,
  }) async {
    final c = _client;
    if (c == null || _userId == null) return Err(_authFailure);
    try {
      final rows = await c
          .from('party_messages')
          .select()
          .eq('party_id', partyId)
          .order('created_at')
          .limit(limit);
      return Ok(
        (rows as List)
            .map((r) => _message(Map<String, Object?>.from(r as Map)))
            .toList(),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<PartyMessage, Failure>> sendMessage(
    String partyId,
    String body,
  ) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      final r = Map<String, Object?>.from(
        await c
                .from('party_messages')
                .insert({'party_id': partyId, 'user_id': u, 'body': body})
                .select()
                .single()
            as Map,
      );
      return Ok(_message(r));
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<List<Post>, Failure>> fetchPartyFeed(
    String partyId, {
    int limit = 20,
  }) async {
    final c = _client;
    if (c == null || _userId == null) return Err(_authFailure);
    try {
      final members = await c
          .from('party_members')
          .select('user_id')
          .eq('party_id', partyId);
      final ids = (members as List)
          .map((m) => (m as Map)['user_id'] as String)
          .toList();
      if (ids.isEmpty) return const Ok(<Post>[]);
      final rows = await c
          .from('posts')
          .select()
          .inFilter('user_id', ids)
          .order('created_at', ascending: false)
          .limit(limit);
      return Ok(
        (rows as List)
            .map((r) => _post(Map<String, Object?>.from(r as Map)))
            .toList(),
      );
    } on Exception catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  // 앞자리가 타임스탬프였던 예전 방식은 같은 시각에 만든 파티끼리 코드가 겹치고
  // 다음 코드도 추측 가능했다. 헷갈리는 0/O/1/I를 뺀 문자로 무작위 생성한다.
  static const String _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static String _code() {
    final random = Random.secure();
    return List<String>.generate(
      6,
      (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// 파티별 인원수. 정책상 읽을 수 없는 파티는 결과에서 빠진다.
  static Future<Map<String, int>> _memberCounts(
    SupabaseClient client,
    List<String> partyIds,
  ) async {
    if (partyIds.isEmpty) return <String, int>{};
    try {
      final rows = rowList(
        await client
            .from('party_members')
            .select('party_id')
            .inFilter('party_id', partyIds),
      );
      final counts = <String, int>{};
      for (final row in rows) {
        final id = rowString(row, 'party_id');
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } on Exception {
      return <String, int>{};
    }
  }

  static Party _party(Map<String, Object?> r) => Party(
    id: rowString(r, 'id'),
    ownerId: rowString(r, 'owner_id'),
    name: rowString(r, 'name'),
    maxMembers: rowInt(r, 'max_members') ?? 0,
    isPublic: rowBool(r, 'is_public'),
    createdAt: rowDate(r, 'created_at'),
    description: rowStringOrNull(r, 'description'),
    region: rowStringOrNull(r, 'region'),
    focus: rowStringOrNull(r, 'focus'),
    joinCode: rowStringOrNull(r, 'join_code'),
  );
  static PartyMessage _message(Map<String, Object?> r) => PartyMessage(
    id: rowString(r, 'id'),
    partyId: rowString(r, 'party_id'),
    userId: rowString(r, 'user_id'),
    body: rowString(r, 'body'),
    createdAt: rowDate(r, 'created_at'),
  );
  static Post _post(Map<String, Object?> r) => Post(
    id: rowString(r, 'id'),
    userId: rowString(r, 'user_id'),
    caption: rowString(r, 'caption'),
    mediaUrl: rowString(r, 'media_url'),
    mediaKind: r['media_kind'] == 'video'
        ? PostMediaKind.video
        : PostMediaKind.photo,
    createdAt: rowDate(r, 'created_at'),
  );
}
