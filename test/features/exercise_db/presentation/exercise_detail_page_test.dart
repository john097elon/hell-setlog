import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/failure.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_themes.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/exercise_guide.dart';
import 'package:heal_setlog/domain/entities/personal_record.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_guide_provider.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/exercise_db/presentation/exercise_detail_page.dart';
import 'package:heal_setlog/features/stats/application/stats_providers.dart';
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
    expect(find.text('아직 기록이 없어요'), findsOneWidget);
  });

  for (final themeId in AppThemeId.values) {
    testWidgets('320px ${themeId.name}에서 거리·시간·속도 기록을 표시한다', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await _pump(tester, records: _records, theme: themeFor(themeId));

      expect(find.text('최장 거리'), findsOneWidget);
      expect(find.text('5km'), findsOneWidget);
      expect(find.text('최장 시간'), findsOneWidget);
      expect(find.text('1시간 1분'), findsOneWidget);
      expect(find.text('최고 속도'), findsOneWidget);
      expect(find.text("5'00\"/km"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  ExerciseGuide? guide,
  List<PersonalRecord> records = const <PersonalRecord>[],
  ThemeData? theme,
}) => tester
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
          personalRecordsProvider(
            'bench',
          ).overrideWith((_) async => Ok(records)),
        ],
        child: MaterialApp(
          theme: theme ?? buildAppTheme(),
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

final _records = <PersonalRecord>[
  PersonalRecord(
    id: 'distance',
    userId: 'user',
    exerciseId: 'bench',
    type: PrType.distance,
    value: 5000,
    achievedAt: DateTime(2026),
    sessionId: 'session',
    updatedAt: DateTime(2026),
  ),
  PersonalRecord(
    id: 'duration',
    userId: 'user',
    exerciseId: 'bench',
    type: PrType.duration,
    value: 3660,
    achievedAt: DateTime(2026),
    sessionId: 'session',
    updatedAt: DateTime(2026),
  ),
  PersonalRecord(
    id: 'speed',
    userId: 'user',
    exerciseId: 'bench',
    type: PrType.speed,
    value: 1000 / 300,
    achievedAt: DateTime(2026),
    sessionId: 'session',
    updatedAt: DateTime(2026),
  ),
];
