import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/routine.dart';
import 'package:heal_setlog/domain/entities/routine_item.dart';
import 'package:heal_setlog/domain/repositories/routine_repository.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/routine/application/routine_providers.dart';
import 'package:heal_setlog/features/routine/presentation/routine_editor_page.dart';
import 'package:heal_setlog/features/workout_log/application/exercise_name_provider.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoutineRepository extends Mock implements RoutineRepository {}

void main() {
  testWidgets('adding a picked exercise calls addItem', (tester) async {
    final repository = _MockRoutineRepository();
    when(
      () => repository.getItems('routine'),
    ).thenAnswer((_) async => const Ok(<RoutineItem>[]));
    when(
      () => repository.getRoutines(),
    ).thenAnswer((_) async => Ok(<Routine>[_routine()]));
    when(
      () => repository.addItem(
        routineId: 'routine',
        exerciseId: 'bench',
        targetSets: 3,
        targetReps: 10,
        targetWeight: 0,
      ),
    ).thenAnswer((_) async => Ok(_item()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          routineRepositoryProvider.overrideWithValue(repository),
          exerciseSearchProvider(
            query: '',
          ).overrideWith(_FakeExerciseSearch.new),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RoutineEditorPage(routineId: 'routine'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench press').first);
    await tester.pumpAndSettle();

    verify(
      () => repository.addItem(
        routineId: 'routine',
        exerciseId: 'bench',
        targetSets: 3,
        targetReps: 10,
        targetWeight: 0,
      ),
    ).called(1);
  });

  testWidgets('기존 루틴을 열면 이름이 채워지고 종목은 UUID 대신 이름으로 보인다', (tester) async {
    final repository = _MockRoutineRepository();
    when(
      () => repository.getItems('routine'),
    ).thenAnswer((_) async => Ok(<RoutineItem>[_item()]));
    when(
      () => repository.getRoutines(),
    ).thenAnswer((_) async => Ok(<Routine>[_routine()]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          routineRepositoryProvider.overrideWithValue(repository),
          exerciseNameProvider('bench').overrideWith((_) async => '벤치 프레스'),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RoutineEditorPage(routineId: 'routine'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 이름이 비어 있으면 저장이 조용히 무시된다.
    expect(find.text('가슴 루틴'), findsOneWidget);
    expect(find.text('벤치 프레스'), findsOneWidget);
    expect(find.text('bench'), findsNothing);
  });
}

class _FakeExerciseSearch extends ExerciseSearch {
  @override
  Future<Result<List<Exercise>, Failure>> build({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) async => const Ok(<Exercise>[
    Exercise(
      id: 'bench',
      name: 'Bench press',
      nameKo: 'Bench press',
      muscleGroup: MuscleGroup.chest,
      equipment: Equipment.barbell,
    ),
  ]);
}

RoutineItem _item() => RoutineItem(
  id: 'item',
  routineId: 'routine',
  exerciseId: 'bench',
  order: 0,
  targetSets: 3,
  targetReps: 10,
  targetWeight: 0,
  updatedAt: DateTime(2026),
);

Routine _routine() => Routine(
  id: 'routine',
  ownerId: 'user',
  name: '가슴 루틴',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
