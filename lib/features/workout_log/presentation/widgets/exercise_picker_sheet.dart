import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_list.dart';
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
                  ok: (items) => ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
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
                          if (index < items.length - 1)
                            const AppHairline(indent: AppSpacing.lg),
                        ],
                      );
                    },
                  ),
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
}
