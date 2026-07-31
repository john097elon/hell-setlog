import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/routine.dart';
import 'package:heal_setlog/domain/entities/routine_item.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/routine/application/routine_providers.dart';
import 'package:heal_setlog/features/routine/presentation/routine_detail_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders routine exercise, prescription, and start button', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('벤치 프레스'), findsOneWidget);
    expect(find.text('3세트 x 10회'), findsOneWidget);
    expect(find.byKey(const Key('start-routine')), findsOneWidget);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px에서 ${themeId.name} 루틴 상세가 넘치지 않는다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(themeId: themeId));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}

Widget _app({AppThemeId themeId = AppThemeId.appleWhite}) => ProviderScope(
  overrides: <Override>[
    routinesProvider.overrideWith((ref) async => Ok(<Routine>[_routine()])),
    routineItemsProvider(
      'routine',
    ).overrideWith((ref) async => Ok(<RoutineItem>[_item()])),
    exerciseByIdProvider('bench').overrideWith(
      (ref) async => const Ok<Exercise, Failure>(
        Exercise(
          id: 'bench',
          name: 'Bench Press',
          nameKo: '벤치 프레스',
          muscleGroup: MuscleGroup.chest,
          equipment: Equipment.barbell,
        ),
      ),
    ),
  ],
  child: MaterialApp(
    theme: themeFor(themeId),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const RoutineDetailPage(routineId: 'routine'),
  ),
);

Routine _routine() => Routine(
  id: 'routine',
  name: '가슴 루틴',
  ownerId: 'user',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

RoutineItem _item() => RoutineItem(
  id: 'item',
  routineId: 'routine',
  exerciseId: 'bench',
  order: 0,
  targetSets: 3,
  targetReps: 10,
  targetWeight: 50,
  updatedAt: DateTime(2026),
);
