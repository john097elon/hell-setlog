import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/exercise_guide.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_guide_provider.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/exercise_db/presentation/exercise_detail_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';

void main() {
  testWidgets('renders an available exercise guide', (tester) async {
    await _pump(tester, guide: _guide);

    expect(find.text('벤치 프레스'), findsOneWidget);
    expect(find.text('요약'), findsOneWidget);
    expect(find.text('수행 순서'), findsOneWidget);
    expect(find.text('가슴'), findsWidgets);
  });

  testWidgets('renders a prepared message when guide is unavailable', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('가이드 준비 중입니다'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, {ExerciseGuide? guide}) => tester
    .pumpWidget(
      ProviderScope(
        overrides: <Override>[
          exerciseByIdProvider(
            'bench',
          ).overrideWith((_) async => const Ok<Exercise, Failure>(_exercise)),
          exerciseGuideProvider.overrideWith(
            (_) async => guide == null
                ? const <String, ExerciseGuide>{}
                : <String, ExerciseGuide>{guide.id: guide},
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExerciseDetailPage(exerciseId: 'bench'),
        ),
      ),
    )
    .then((_) => tester.pumpAndSettle());

const _exercise = Exercise(
  id: 'bench',
  name: 'Bench Press',
  nameKo: '벤치 프레스',
  muscleGroup: MuscleGroup.chest,
  equipment: Equipment.barbell,
);

const _guide = ExerciseGuide(
  id: 'bench',
  nameKo: '벤치 프레스',
  summary: '가슴을 단련하는 운동입니다.',
  steps: <String>['벤치에 눕습니다.'],
  tips: <String>['가슴에 집중합니다.'],
  mistakes: <String>['반동을 사용하지 않습니다.'],
  primaryMuscles: <String>['가슴'],
  beginnerFriendly: true,
);
