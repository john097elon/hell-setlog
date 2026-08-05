import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../remote/row_parse.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/character_identity.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/party.dart';
import '../../domain/entities/party_member.dart';
import '../../domain/entities/party_mission.dart';
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
      final values = rowList(rows)
          // 정책이 파티를 가리면 조인 결과가 비어 온다. 그때 캐스팅으로 죽지 않는다.
          .map((r) => mine ? rowNested(r, 'parties') : r)
          .nonNulls
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
    } on Object catch (e) {
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
      // 소유자 멤버 행은 parties 트리거가 만든다.
      return Ok(_party(row));
    } on Object catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Future<Result<void, Failure>> joinParty(String partyId) =>
      _join('join_party', <String, Object?>{'p_party': partyId});

  @override
  Future<Result<void, Failure>> joinByCode(String code) => _join(
    'join_party_by_code',
    <String, Object?>{'p_code': code.trim().toUpperCase()},
  );

  /// 가입 검증은 서버 함수가 한다. 클라이언트는 정원·비공개를 판단하지 않는다.
  Future<Result<void, Failure>> _join(
    String function,
    Map<String, Object?> params,
  ) async {
    final c = _client;
    if (c == null || _userId == null) return Err(_authFailure);
    try {
      final outcome = await c.rpc<Object?>(function, params: params);
      return switch (outcome) {
        'ok' => const Ok<void, Failure>(null),
        'full' => const Err<void, Failure>(DatabaseFailure('정원이 가득 찼습니다')),
        'code_required' => const Err<void, Failure>(
          DatabaseFailure('참여 코드가 올바르지 않습니다'),
        ),
        'not_found' => const Err<void, Failure>(
          DatabaseFailure('파티를 찾을 수 없습니다'),
        ),
        _ => const Err<void, Failure>(DatabaseFailure('파티에 참여하지 못했습니다')),
      };
    } on Object catch (e) {
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
    } on Object catch (e) {
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
          .select(
            'user_id,role,joined_at,profiles(nickname,avatar_url,character_name,'
            'character_species,character_level,character_stage,'
            'character_discipline)',
          )
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
            characterName: profile == null
                ? null
                : rowStringOrNull(profile, 'character_name'),
            characterSpecies: profile == null
                ? null
                : (rowStringOrNull(profile, 'character_species') == null
                      ? null
                      : speciesFrom(
                          rowStringOrNull(profile, 'character_species'),
                        )),
            characterLevel: profile == null
                ? null
                : rowInt(profile, 'character_level'),
            characterStage: profile == null
                ? null
                : rowInt(profile, 'character_stage'),
            characterDiscipline: profile == null
                ? null
                : (rowStringOrNull(profile, 'character_discipline') == null
                      ? null
                      : disciplineFrom(
                          rowStringOrNull(profile, 'character_discipline'),
                        )),
          );
        }).toList(),
      );
    } on Object catch (e) {
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
          .order('created_at', ascending: false)
          .limit(limit);
      return Ok(rowList(rows).map(_message).toList());
    } on Object catch (e) {
      return Err(DatabaseFailure('$e'));
    }
  }

  @override
  Stream<Result<List<PartyMessage>, Failure>> watchMessages(
    String partyId, {
    int limit = 50,
  }) async* {
    final c = _client;
    if (c == null || _userId == null) {
      yield const Ok(<PartyMessage>[]);
      return;
    }
    try {
      await for (final rows
          in c
              .from('party_messages')
              .stream(primaryKey: const <String>['id'])
              .eq('party_id', partyId)
              .order('created_at', ascending: false)
              .limit(limit)) {
        yield Ok(
          <String, PartyMessage>{
            for (final row in rowList(rows))
              rowString(row, 'id'): _message(row),
          }.values.toList(),
        );
      }
    } on Object {
      yield await fetchMessages(partyId, limit: limit);
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
    } on Object catch (e) {
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
      final ids = rowList(members)
          .map((m) => rowString(m, 'user_id'))
          .where((id) => id.isNotEmpty)
          .toList();
      if (ids.isEmpty) return const Ok(<Post>[]);
      final rows = await c
          .from('posts')
          .select()
          .inFilter('user_id', ids)
          .order('created_at', ascending: false)
          .limit(limit);
      return Ok(rowList(rows).map(_post).toList());
    } on Object catch (e) {
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

  @override
  Future<Result<PartyMission, Failure>> fetchMission(String partyId) async {
    final c = _client;
    if (c == null || _userId == null) return Err(_authFailure);
    try {
      final weekStart = weekStartOf(DateTime.now());
      final party = Map<String, Object?>.from(
        await c
                .from('parties')
                .select('max_members, weekly_goal')
                .eq('id', partyId)
                .single()
            as Map,
      );
      final members = rowList(
        await c
            .from('party_members')
            .select('user_id, profiles(nickname, avatar_url)')
            .eq('party_id', partyId),
      );
      final rows = rowList(
        await c
            .from('party_activities')
            .select('user_id, volume_kg, xp')
            .eq('party_id', partyId)
            .gte('performed_at', weekStart.toUtc().toIso8601String()),
      );
      final sessions = <String, int>{};
      final volumes = <String, double>{};
      final xps = <String, int>{};
      for (final row in rows) {
        final userId = rowString(row, 'user_id');
        sessions[userId] = (sessions[userId] ?? 0) + 1;
        volumes[userId] =
            (volumes[userId] ?? 0) + (rowDouble(row, 'volume_kg') ?? 0);
        xps[userId] = (xps[userId] ?? 0) + (rowInt(row, 'xp') ?? 0);
      }
      final contributions =
          members.map((member) {
            final userId = rowString(member, 'user_id');
            final profile = rowNested(member, 'profiles');
            return PartyContribution(
              userId: userId,
              nickname: profile == null
                  ? '회원'
                  : rowString(profile, 'nickname', fallback: '회원'),
              avatarUrl: profile == null
                  ? null
                  : rowStringOrNull(profile, 'avatar_url'),
              sessions: sessions[userId] ?? 0,
              volumeKg: volumes[userId] ?? 0,
              xp: xps[userId] ?? 0,
            );
          }).toList()..sort((a, b) {
            final byXp = b.xp.compareTo(a.xp);
            return byXp != 0 ? byXp : b.sessions.compareTo(a.sessions);
          });
      final goal =
          rowInt(party, 'weekly_goal') ?? defaultWeeklyGoal(members.length);
      return Ok(
        PartyMission(
          goalSessions: goal,
          doneSessions: rows.length,
          contributions: contributions,
          weekStart: weekStart,
        ),
      );
    } on Object catch (e) {
      return Err(DatabaseFailure('미션을 불러오지 못했습니다: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> recordActivity({
    required String sessionId,
    required double volumeKg,
    required int xp,
  }) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      final memberships = rowList(
        await c.from('party_members').select('party_id').eq('user_id', u),
      );
      if (memberships.isEmpty) return const Ok(null);
      // 같은 세션을 다시 올려도 unique 제약이 막는다.
      await c
          .from('party_activities')
          .upsert(
            <Map<String, Object?>>[
              for (final row in memberships)
                <String, Object?>{
                  'party_id': rowString(row, 'party_id'),
                  'user_id': u,
                  'session_id': sessionId,
                  'volume_kg': volumeKg,
                  'xp': xp,
                },
            ],
            onConflict: 'party_id,session_id',
            ignoreDuplicates: true,
          );
      return const Ok(null);
    } on Object catch (e) {
      return Err(DatabaseFailure('파티에 기록을 남기지 못했습니다: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> updateWeeklyGoal(
    String partyId,
    int? goalSessions,
  ) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      // 목표 변경은 파티장만 할 수 있다. RLS가 다시 막아 준다.
      await c
          .from('parties')
          .update(<String, Object?>{'weekly_goal': goalSessions})
          .eq('id', partyId)
          .eq('owner_id', u);
      return const Ok(null);
    } on Object catch (e) {
      return Err(DatabaseFailure('목표를 저장하지 못했습니다: $e'));
    }
  }

  /// 내 캐릭터 성장 수치를 프로필에 남긴다. 파티원이 보기 위한 값이다.
  @override
  Future<Result<void, Failure>> publishCharacterStats({
    required int level,
    required int stage,
    required int xp,
    Discipline? discipline,
  }) async {
    final c = _client;
    final u = _userId;
    if (c == null || u == null) return Err(_authFailure);
    try {
      await c
          .from('profiles')
          .update(<String, Object?>{
            'character_level': level,
            'character_stage': stage,
            'character_xp': xp,
            'character_discipline': discipline == null
                ? null
                : disciplineKey(discipline),
            'character_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', u);
      return const Ok(null);
    } on Object catch (e) {
      return Err(DatabaseFailure('$e'));
    }
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
    } on Object {
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
