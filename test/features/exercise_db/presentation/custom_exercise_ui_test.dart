import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/core/widgets/app_list.dart';
import 'package:heal_setlog/domain/entities/discipline.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/repositories/exercise_repository.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/search/presentation/search_page.dart';
import 'package:heal_setlog/features/workout_log/presentation/widgets/exercise_picker_sheet.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  for (final themeId in AppThemeId.values) {
    testWidgets('320px ${themeId.name}에서 커스텀 종목을 만들면 검색에 바로 보인다', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final repository = _ExerciseRepository();

      await _pump(tester, repository, themeFor(themeId), const _PickerHost());
      await tester.tap(find.byKey(const ValueKey<String>('open-picker')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '파쿠르');
      await tester.pumpAndSettle();

      expect(find.text("'파쿠르' 직접 만들기"), findsOneWidget);
      await tester.tap(find.text("'파쿠르' 직접 만들기"));
      await tester.pumpAndSettle();

      final createButton = find.widgetWithText(FilledButton, '만들기');
      expect(tester.widget<FilledButton>(createButton).onPressed, isNull);
      await tester.tap(find.byType(DropdownButtonFormField<Discipline>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('기타').last);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppRow), matching: find.text('파쿠르')),
        findsOneWidget,
      );
      expect(
        repository.items.singleWhere((item) => item.nameKo == '파쿠르').discipline,
        Discipline.other,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('기본 종목에는 삭제가 없고 커스텀 종목은 확인 후 삭제한다', (tester) async {
    final repository = _ExerciseRepository(includeCustom: true);
    await _pump(
      tester,
      repository,
      themeFor(AppThemeId.appleWhite),
      const SearchPage(),
    );
    await tester.tap(find.text('종목'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('delete-default')), findsNothing);
    expect(find.byKey(const ValueKey<String>('delete-custom')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('delete-custom')));
    await tester.pumpAndSettle();
    expect(find.text("'파쿠르' 종목을 삭제할까요?"), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('파쿠르'), findsNothing);
    expect(find.text('벤치 프레스'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _ExerciseRepository repository,
  ThemeData theme,
  Widget home,
) => tester.pumpWidget(
  ProviderScope(
    overrides: <Override>[
      exerciseRepositoryProvider.overrideWith((_) async => repository),
    ],
    child: MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ),
);

class _PickerHost extends StatelessWidget {
  const _PickerHost();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        key: const ValueKey<String>('open-picker'),
        onPressed: () => showExercisePickerSheet(context, (_) {}),
        child: const Text('종목 선택'),
      ),
    ),
  );
}

class _ExerciseRepository implements ExerciseRepository {
  _ExerciseRepository({bool includeCustom = false})
    : items = <Exercise>[_defaultExercise, if (includeCustom) _customExercise];

  final List<Exercise> items;

  @override
  Future<Result<Exercise, Failure>> createCustom({
    required String nameKo,
    required Discipline discipline,
    MuscleGroup muscleGroup = MuscleGroup.fullBody,
    Equipment equipment = Equipment.other,
  }) async {
    final exercise = Exercise(
      id: 'custom',
      name: nameKo,
      nameKo: nameKo,
      muscleGroup: muscleGroup,
      equipment: equipment,
      discipline: discipline,
      isCustom: true,
    );
    items.add(exercise);
    return Ok(exercise);
  }

  @override
  Future<Result<void, Failure>> deleteCustom(String id) async {
    items.removeWhere((item) => item.id == id && item.isCustom);
    return const Ok(null);
  }

  @override
  Future<Result<List<Exercise>, Failure>> getAll() async => Ok(items);

  @override
  Future<Result<Exercise, Failure>> getById(String id) async {
    final matches = items.where((item) => item.id == id);
    return matches.isEmpty ? const Err(NotFoundFailure()) : Ok(matches.single);
  }

  @override
  Future<Result<List<Exercise>, Failure>> search({
    String? query,
    MuscleGroup? muscleGroup,
    Equipment? equipment,
  }) async {
    final normalized = query?.trim().toLowerCase() ?? '';
    return Ok(
      items
          .where(
            (item) =>
                (normalized.isEmpty ||
                    item.nameKo.toLowerCase().contains(normalized)) &&
                (muscleGroup == null || item.muscleGroup == muscleGroup) &&
                (equipment == null || item.equipment == equipment),
          )
          .toList(growable: false),
    );
  }
}

const _defaultExercise = Exercise(
  id: 'default',
  name: 'Bench Press',
  nameKo: '벤치 프레스',
  muscleGroup: MuscleGroup.chest,
  equipment: Equipment.barbell,
);

const _customExercise = Exercise(
  id: 'custom',
  name: 'Parkour',
  nameKo: '파쿠르',
  muscleGroup: MuscleGroup.fullBody,
  equipment: Equipment.other,
  discipline: Discipline.other,
  isCustom: true,
);
