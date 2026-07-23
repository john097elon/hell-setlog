import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/exercise.dart';
import '../../../exercise_db/application/exercise_providers.dart';

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
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
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
                      return ListTile(
                        title: Text(item.nameKo),
                        subtitle: Text(item.name),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelected(item);
                        },
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
