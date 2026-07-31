import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_list.dart';
import '../../../domain/entities/character_identity.dart';
import '../../../domain/usecases/calculate_character_growth.dart';
import '../application/character_identity_controller.dart';
import 'widgets/growth_view.dart';

/// 캐릭터를 처음 만드는 화면. 종족 → 성향 → 이름 순으로 고른다.
class CharacterSetupPage extends ConsumerStatefulWidget {
  const CharacterSetupPage({this.initial, super.key});

  /// 이미 만든 캐릭터를 고칠 때 넘긴다.
  final CharacterIdentity? initial;

  @override
  ConsumerState<CharacterSetupPage> createState() => _CharacterSetupPageState();
}

class _CharacterSetupPageState extends ConsumerState<CharacterSetupPage> {
  late CharacterSpecies _species =
      widget.initial?.species ?? CharacterSpecies.cat;
  late CharacterTrait _trait = widget.initial?.trait ?? CharacterTrait.balanced;
  late final TextEditingController _name = TextEditingController(
    text: widget.initial?.name ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름을 지어 주세요')));
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(characterIdentityControllerProvider)
        .save(CharacterIdentity(species: _species, trait: _trait, name: name));
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final editing = widget.initial != null;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(title: Text(editing ? '캐릭터 바꾸기' : '캐릭터 만들기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          _Preview(species: _species, name: _name.text.trim()),
          const SizedBox(height: AppSpacing.xl),
          AppSection(
            title: '종족',
            children: <Widget>[
              for (final species in CharacterSpecies.values)
                _SpeciesTile(
                  species: species,
                  selected: species == _species,
                  onTap: () => setState(() => _species = species),
                ),
            ],
          ),
          AppSection(
            title: '성향',
            footer: '고른 반복 구간의 세트에서 경험치를 25% 더 받아요. 나중에 바꿀 수 있어요.',
            children: <Widget>[
              for (final trait in CharacterTrait.values)
                _TraitTile(
                  trait: trait,
                  selected: trait == _trait,
                  onTap: () => setState(() => _trait = trait),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text('이름', style: AppText.sectionLabel(context)),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _name,
            maxLength: 12,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              hintText: '내 캐릭터 이름',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '저장 중' : (editing ? '저장' : '함께 시작하기')),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.species, required this.name});

  final CharacterSpecies species;
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: <Widget>[
          Image.asset(
            stageAsset(species, 0),
            width: 144,
            height: 144,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Icon(Icons.pets_rounded, size: 88, color: t.brand),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            name.isEmpty ? speciesCopy(species).name : name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            speciesCopy(species).detail,
            style: TextStyle(fontSize: 12.5, color: t.mutedText),
          ),
        ],
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  const _SpeciesTile({
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final CharacterSpecies species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = speciesCopy(species);
    return AppRow(
      onTap: onTap,
      leading: Image.asset(
        stageAsset(species, 0),
        width: AppSpacing.xxl,
        height: AppSpacing.xxl,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, _, _) =>
            Icon(Icons.pets_rounded, color: context.tokens.brand),
      ),
      title: copy.name,
      subtitle: copy.detail,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? context.tokens.brand : context.tokens.faintText,
      ),
    );
  }
}

class _TraitTile extends StatelessWidget {
  const _TraitTile({
    required this.trait,
    required this.selected,
    required this.onTap,
  });

  final CharacterTrait trait;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = traitCopy(trait);
    final icon = switch (trait) {
      CharacterTrait.power => Icons.fitness_center_rounded,
      CharacterTrait.endurance => Icons.directions_run_rounded,
      CharacterTrait.balanced => Icons.balance_rounded,
    };
    return AppRow(
      onTap: onTap,
      leading: Icon(icon, color: context.tokens.brand),
      title: copy.name,
      subtitle: copy.detail,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? context.tokens.brand : context.tokens.faintText,
      ),
    );
  }
}
