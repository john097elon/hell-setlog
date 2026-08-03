import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/repositories/exercise_repository.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/search/presentation/search_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  test('갈래 필터는 선택한 종목만 남긴다', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        exerciseRepositoryProvider.overrideWith(
          (_) async => const _ExerciseRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      exerciseSearchProvider(discipline: Discipline.running).future,
    );

    expect(
      result.when(
        ok: (items) => items.map((item) => item.nameKo).toList(),
        err: (failure) => throw failure,
      ),
      <String>['야외 러닝'],
    );
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px ${themeId.name}에서 러닝 선택 시 근육군 필터를 숨긴다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            exerciseRepositoryProvider.overrideWith(
              (_) async => const _ExerciseRepository(),
            ),
          ],
          child: MaterialApp(
            theme: themeFor(themeId),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SearchPage(),
          ),
        ),
      );
      await tester.tap(find.text('종목'));
      await tester.pumpAndSettle();

      expect(find.text('근육군'), findsOneWidget);
      await tester.tap(find.text('전체').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('러닝').last);
      await tester.pumpAndSettle();

      expect(find.text('근육군'), findsNothing);
      expect(find.text('야외 러닝'), findsOneWidget);
      expect(find.text('벤치 프레스'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

class _ExerciseRepository implements ExerciseRepository {
  @override
  Future<Result<Exercise, Failure>> createCustom({
    required String nameKo,
    required Discipline discipline,
    MuscleGroup muscleGroup = MuscleGroup.fullBody,
    Equipment equipment = Equipment.other,
  }) async => const Err(NotFoundFailure());

  @override
  Future<Result<void, Failure>> deleteCustom(String id) async =>
      const Err(NotFoundFailure());

  const _ExerciseRepository();

  static const _items = <Exercise>[
    Exercise(
      id: 'strength',
      name: 'Bench Press',
      nameKo: '벤치 프레스',
      muscleGroup: MuscleGroup.chest,
      equipment: Equipment.barbell,
    ),
    Exercise(
      id: 'running',
      name: 'Outdoor Running',
      nameKo: '야외 러닝',
      muscleGroup: MuscleGroup.fullBody,
      equipment: Equipment.other,
      discipline: Discipline.running,
    ),
  ];

  @override
  Future<Result<List<Exercise>, Failure>> getAll() async => const Ok(_items);

  @override
  Future<Result<Exercise, Failure>> getById(String id) async =>
      Ok(_items.firstWhere((item) => item.id == id));

  @override
  Future<Result<List<Exercise>, Failure>> search({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) async => const Ok(_items);
}
