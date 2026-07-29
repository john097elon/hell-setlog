import 'package:supabase_flutter/supabase_flutter.dart';

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
      return Ok(values);
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
        (rows as List).map((r) {
          final m = r as Map;
          final p = m['profiles'] as Map?;
          return PartyMember(
            userId: m['user_id'] as String,
            nickname: p?['nickname'] as String? ?? '회원',
            avatarUrl: p?['avatar_url'] as String?,
            role: m['role'] as String,
            joinedAt: DateTime.parse(m['joined_at'] as String),
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

  static String _code() => DateTime.now().microsecondsSinceEpoch
      .toRadixString(36)
      .toUpperCase()
      .padLeft(6, '0')
      .substring(0, 6);
  static Party _party(Map<String, Object?> r) => Party(
    id: r['id'] as String,
    ownerId: r['owner_id'] as String,
    name: r['name'] as String,
    maxMembers: (r['max_members'] as num).toInt(),
    isPublic: r['is_public'] as bool,
    createdAt: DateTime.parse(r['created_at'] as String),
    description: r['description'] as String?,
    region: r['region'] as String?,
    focus: r['focus'] as String?,
    joinCode: r['join_code'] as String?,
  );
  static PartyMessage _message(Map<String, Object?> r) => PartyMessage(
    id: r['id'] as String,
    partyId: r['party_id'] as String,
    userId: r['user_id'] as String,
    body: r['body'] as String,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
  static Post _post(Map<String, Object?> r) => Post(
    id: r['id'] as String,
    userId: r['user_id'] as String,
    caption: r['caption'] as String? ?? '',
    mediaUrl: r['media_url'] as String,
    mediaKind: r['media_kind'] == 'video'
        ? PostMediaKind.video
        : PostMediaKind.photo,
    createdAt: DateTime.parse(r['created_at'] as String),
  );
}
