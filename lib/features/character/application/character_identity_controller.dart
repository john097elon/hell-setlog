import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../../domain/entities/character_identity.dart';

const String _speciesKey = 'character_species';
const String _traitKey = 'character_trait';
const String _nameKey = 'character_name';

/// 내가 만든 캐릭터. 아직 고르지 않았으면 null이다.
final characterIdentityProvider = FutureProvider<CharacterIdentity?>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final local = _read(prefs);
  if (local != null) return local;

  // 기기를 바꿨을 수 있으니 서버 프로필도 본다.
  final client = ref.watch(supabaseClientProvider);
  final userId = client?.auth.currentUser?.id;
  if (client == null || userId == null) return null;
  try {
    final row = await client
        .from('profiles')
        .select('character_species, character_trait, character_name')
        .eq('user_id', userId)
        .maybeSingle();
    final name = (row?['character_name'] as String?)?.trim();
    if (name == null || name.isEmpty) return null;
    final identity = CharacterIdentity(
      species: speciesFrom(row?['character_species'] as String?),
      trait: traitFrom(row?['character_trait'] as String?),
      name: name,
    );
    await _write(prefs, identity);
    return identity;
  } on Object {
    return null;
  }
});

/// 캐릭터 생성·수정을 한곳에서 처리한다.
final characterIdentityControllerProvider =
    Provider<CharacterIdentityController>(
      (ref) => CharacterIdentityController(ref),
    );

class CharacterIdentityController {
  const CharacterIdentityController(this._ref);

  final Ref _ref;

  /// 로컬에 먼저 저장해 오프라인에서도 캐릭터를 잃지 않는다.
  Future<void> save(CharacterIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await _write(prefs, identity);
    await _push(identity);
    _ref.invalidate(characterIdentityProvider);
  }

  Future<void> _push(CharacterIdentity identity) async {
    final client = _ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('profiles')
          .update(<String, Object?>{
            'character_species': speciesKey(identity.species),
            'character_trait': traitKey(identity.trait),
            'character_name': identity.name,
          })
          .eq('user_id', userId);
    } on Object {
      // 서버 저장 실패는 로컬 캐릭터를 되돌리지 않는다. 다음 저장에서 다시 올라간다.
    }
  }
}

CharacterIdentity? _read(SharedPreferences prefs) {
  final name = prefs.getString(_nameKey)?.trim();
  if (name == null || name.isEmpty) return null;
  return CharacterIdentity(
    species: speciesFrom(prefs.getString(_speciesKey)),
    trait: traitFrom(prefs.getString(_traitKey)),
    name: name,
  );
}

Future<void> _write(SharedPreferences prefs, CharacterIdentity identity) async {
  await prefs.setString(_speciesKey, speciesKey(identity.species));
  await prefs.setString(_traitKey, traitKey(identity.trait));
  await prefs.setString(_nameKey, identity.name);
}
