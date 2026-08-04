import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/build_context_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../domain/entities/discipline.dart';
import '../../../../domain/entities/exercise.dart';
import '../../../exercise_db/application/exercise_providers.dart';
import '../../../exercise_db/presentation/exercise_detail_page.dart';
import '../../../exercise_db/presentation/widgets/exercise_thumbnail.dart';

Future<void> showExercisePickerSheet(
  BuildContext context,
  ValueChanged<Exercise> onSelected,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ExercisePickerSheet(onSelected: onSelected),
);

class _ExercisePickerSheet extends ConsumerStatefulWidget {
  const _ExercisePickerSheet({required this.onSelected});
  final ValueChanged<Exercise> onSelected;
  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  String _query = '';
  Discipline? _discipline;

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(exerciseSearchProvider(query: _query));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  FilterChip(
                    label: const Text('전체'),
                    selected: _discipline == null,
                    onSelected: (_) => setState(() => _discipline = null),
                  ),
                  for (final discipline in Discipline.values) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(disciplineLabel(discipline)),
                      selected: _discipline == discipline,
                      onSelected: (_) =>
                          setState(() => _discipline = discipline),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '종목 검색',
                ),
              ),
            ),
            SizedBox(
              height: 360,
              child: results.when(
                data: (result) => result.when(
                  ok: (items) {
                    final filtered = _discipline == null
                        ? items
                        : items
                              .where((item) => item.discipline == _discipline)
                              .toList(growable: false);
                    if (filtered.isEmpty && _query.trim().isNotEmpty) {
                      return ListView(
                        children: <Widget>[
                          AppPagePadding(
                            child: AppSection(
                              children: <Widget>[
                                AppRow(
                                  title: context.l10n
                                      .customExerciseDirectCreate(
                                        _query.trim(),
                                      ),
                                  subtitle:
                                      context.l10n.customExerciseDisciplineHelp,
                                  leading: const Icon(Icons.add_rounded),
                                  onTap: () => _createCustom(_query.trim()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AppRow(
                              title: item.nameKo,
                              subtitle: equipmentLabelKo(item.equipment),
                              leading: ExerciseThumbnail(
                                equipment: item.equipment,
                                thumbnailUrl: item.thumbnailUrl,
                                size: AppSpacing.xxl,
                              ),
                              trailing: IconButton(
                                tooltip: '${item.nameKo} 정보',
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ExerciseDetailPage(exerciseId: item.id),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onSelected(item);
                              },
                            ),
                            if (index < filtered.length - 1)
                              const AppHairline(indent: AppSpacing.lg),
                          ],
                        );
                      },
                    );
                  },
                  err: (failure) => Center(child: Text(failure.message)),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCustom(String nameKo) async {
    FocusScope.of(context).unfocus();
    final created = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateCustomExerciseSheet(nameKo: nameKo),
    );
    if (created != null && mounted) {
      setState(() => _discipline = created.discipline);
    }
  }
}

class _CreateCustomExerciseSheet extends ConsumerStatefulWidget {
  const _CreateCustomExerciseSheet({required this.nameKo});

  final String nameKo;

  @override
  ConsumerState<_CreateCustomExerciseSheet> createState() =>
      _CreateCustomExerciseSheetState();
}

class _CreateCustomExerciseSheetState
    extends ConsumerState<_CreateCustomExerciseSheet> {
  Discipline? _discipline;
  bool _saving = false;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: AppPagePadding(
      top: AppSpacing.lg,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.l10n.customExerciseCreateTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.nameKo),
            const SizedBox(height: AppSpacing.lg),
            AppSection(
              footer: context.l10n.customExerciseDisciplineHelp,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: DropdownButtonFormField<Discipline>(
                    initialValue: _discipline,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.customExerciseDisciplinePrompt,
                    ),
                    items: <DropdownMenuItem<Discipline>>[
                      for (final discipline in Discipline.values)
                        DropdownMenuItem<Discipline>(
                          value: discipline,
                          child: Text(disciplineLabel(discipline)),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _discipline = value),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _discipline == null || _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: AppSpacing.xl,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.customExerciseCreate),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref
        .read(customExerciseControllerProvider)
        .create(nameKo: widget.nameKo, discipline: _discipline!);
    if (!mounted) return;
    result.when(
      ok: (exercise) => Navigator.pop(context, exercise),
      err: (failure) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }
}
