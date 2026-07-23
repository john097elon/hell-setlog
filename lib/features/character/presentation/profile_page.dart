import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';

/// 캐릭터 성장과 운동 취향을 보여주는 로컬 프로필 목업 화면이다.
class ProfilePage extends StatefulWidget {
  /// 프로필 목업 화면을 생성한다.
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Set<String> _selectedTags = <String>{};

  void _toggleTag(String tag) {
    setState(() {
      if (!_selectedTags.add(tag)) {
        _selectedTags.remove(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final List<String> tags = <String>[
      copy.tagStrength,
      copy.tagCardio,
      copy.tagHomeTraining,
      copy.tagCrossfit,
      copy.tagYoga,
      copy.tagRunning,
      copy.tagSwimming,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(copy.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: context.tokens.brand,
                    child: Icon(
                      Icons.person_rounded,
                      color: context.tokens.onBrand,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    copy.sampleCurrentUser,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${copy.level} 12'),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    initialValue: copy.sampleCurrentUser,
                    decoration: InputDecoration(labelText: copy.nickname),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: 'hellsetlog',
                    decoration: InputDecoration(labelText: copy.avatarSeed),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _StatRow(label: copy.strength, value: 0.78),
                  _StatRow(label: copy.endurance, value: 0.62),
                  _StatRow(label: copy.consistency, value: 0.9),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(copy.workoutTags, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: tags
                .map(
                  (String tag) => FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    onSelected: (bool _) => _toggleTag(tag),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(copy.saved))),
            child: Text(copy.save),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(copy.mockOnlyNotice, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: value, minHeight: 8),
        ],
      ),
    );
  }
}
