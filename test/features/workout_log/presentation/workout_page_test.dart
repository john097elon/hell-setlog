import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heal_setlog/core/error/result.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/domain/entities/exercise.dart';
import 'package:heal_setlog/domain/entities/workout_session.dart';
import 'package:heal_setlog/domain/entities/workout_set.dart';
import 'package:heal_setlog/domain/repositories/exercise_repository.dart';
import 'package:heal_setlog/domain/repositories/workout_repository.dart';
import 'package:heal_setlog/features/exercise_db/application/exercise_providers.dart';
import 'package:heal_setlog/features/workout_log/application/exercise_name_provider.dart';
import 'package:heal_setlog/features/workout_log/application/workout_providers.dart';
import 'package:heal_setlog/features/workout_log/presentation/workout_page.dart';
import 'package:heal_setlog/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockExerciseRepository extends Mock implements ExerciseRepository {}

class _MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  final session = WorkoutSession(
    id: 'session',
    userId: 'user',
    startedAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final recordedSet = WorkoutSet(
    id: 'set-1',
    sessionId: session.id,
    exerciseId: '0000-uuid-hidden',
    setIndex: 0,
    weight: 60,
    reps: 10,
    isCompleted: true,
    updatedAt: DateTime(2026),
  );

  testWidgets('shows exercise name, never its UUID, and adds a set row', (
    tester,
  ) async {
    final workoutRepository = _MockWorkoutRepository();
    await _pumpPage(tester, workoutRepository, session, [recordedSet]);

    expect(find.text('벤치 프레스'), findsOneWidget);
    expect(find.textContaining('0000'), findsNothing);
    expect(find.text('KG'), findsOneWidget);

    // 기록된 세트 1개(체크박스 1) + 명시적 세트 추가 1개(체크박스 1) = 2.
    await tester.tap(find.byKey(const Key('add-set-벤치 프레스')));
    await tester.pump();
    expect(find.byKey(const Key('complete-set')), findsNWidgets(2));
  });

  testWidgets('completes a draft set with one tap', (tester) async {
    final workoutRepository = _MockWorkoutRepository();
    final added = recordedSet.copyWith(id: 'draft', isCompleted: false);
    when(
      () => workoutRepository.addSet(
        sessionId: any(named: 'sessionId'),
        exerciseId: any(named: 'exerciseId'),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        rpe: any(named: 'rpe'),
        isWarmup: any(named: 'isWarmup'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => Ok(added));
    when(
      () => workoutRepository.completeSet(
        any(),
        completed: any(named: 'completed'),
      ),
    ).thenAnswer((_) async => Ok(added.copyWith(isCompleted: true)));
    await _pumpPage(tester, workoutRepository, session, [recordedSet]);

    // 명시적으로 세트를 추가한 뒤 그 draft의 완료 체크를 한 번 탭한다.
    await tester.tap(find.byKey(const Key('add-set-벤치 프레스')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('complete-set')).last);
    await tester.pump();

    verify(() => workoutRepository.completeSet('draft')).called(1);
  });

  testWidgets('앞 세트를 완료해도 뒤 세트에 입력한 값이 남는다', (tester) async {
    final workoutRepository = _MockWorkoutRepository();
    final added = recordedSet.copyWith(id: 'draft', isCompleted: false);
    when(
      () => workoutRepository.addSet(
        sessionId: any(named: 'sessionId'),
        exerciseId: any(named: 'exerciseId'),
        weight: any(named: 'weight'),
        reps: any(named: 'reps'),
        rpe: any(named: 'rpe'),
        isWarmup: any(named: 'isWarmup'),
        restSeconds: any(named: 'restSeconds'),
      ),
    ).thenAnswer((_) async => Ok(added));
    when(
      () => workoutRepository.completeSet(
        any(),
        completed: any(named: 'completed'),
      ),
    ).thenAnswer((_) async => Ok(added.copyWith(isCompleted: true)));
    await _pumpPage(tester, workoutRepository, session, [recordedSet]);

    await tester.tap(find.byKey(const Key('add-set-벤치 프레스')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-set-벤치 프레스')));
    await tester.pump();

    final weightFields = find.byKey(const Key('set-weight-input'));
    expect(weightFields, findsNWidgets(2));
    await tester.enterText(weightFields.last, '100');
    await tester.pump();

    // 첫 draft 줄 완료. 기록된 세트가 index 0이므로 draft는 1번부터다.
    await tester.tap(find.byKey(const Key('complete-set')).at(1));
    await tester.pumpAndSettle();

    final remaining = tester.widget<TextField>(
      find.byKey(const Key('set-weight-input')),
    );
    expect(remaining.controller?.text, '100');
  });

  testWidgets('운동을 끝내면 추가했던 종목이 다음 세션에 남지 않는다', (tester) async {
    final workoutRepository = _MockWorkoutRepository();
    final exerciseRepository = _MockExerciseRepository();
    const squat = Exercise(
      id: 'squat-id',
      name: 'Squat',
      nameKo: '스쿼트',
      muscleGroup: MuscleGroup.legs,
      equipment: Equipment.barbell,
    );
    when(
      () => exerciseRepository.search(
        query: any(named: 'query'),
        muscleGroup: any(named: 'muscleGroup'),
        equipment: any(named: 'equipment'),
      ),
    ).thenAnswer((_) async => const Ok([squat]));
    when(
      () => workoutRepository.endSession(any()),
    ).thenAnswer((_) async => Ok(session));
    await _pumpPage(tester, workoutRepository, session, [
      recordedSet,
    ], exerciseRepository: exerciseRepository);

    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스쿼트'));
    await tester.pumpAndSettle();
    expect(find.text('스쿼트'), findsOneWidget);

    await tester.tap(find.byKey(const Key('finish-workout')));
    await tester.pumpAndSettle();

    expect(find.text('스쿼트'), findsNothing);
  });

  testWidgets('adds an exercise through the picker', (tester) async {
    final workoutRepository = _MockWorkoutRepository();
    final exerciseRepository = _MockExerciseRepository();
    const squat = Exercise(
      id: 'squat-id',
      name: 'Squat',
      nameKo: '스쿼트',
      muscleGroup: MuscleGroup.legs,
      equipment: Equipment.barbell,
    );
    when(
      () => exerciseRepository.search(
        query: any(named: 'query'),
        muscleGroup: any(named: 'muscleGroup'),
        equipment: any(named: 'equipment'),
      ),
    ).thenAnswer((_) async => const Ok([squat]));
    await _pumpPage(tester, workoutRepository, session, [
      recordedSet,
    ], exerciseRepository: exerciseRepository);

    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스쿼트'));
    await tester.pumpAndSettle();

    expect(find.text('스쿼트'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  WorkoutRepository workoutRepository,
  WorkoutSession session,
  List<WorkoutSet> sets, {
  ExerciseRepository? exerciseRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(workoutRepository),
        activeSessionProvider.overrideWith((_) async => Ok(session)),
        sessionSetsProvider(session.id).overrideWith((_) => Stream.value(sets)),
        exerciseNameProvider(
          '0000-uuid-hidden',
        ).overrideWith((_) async => '벤치 프레스'),
        if (exerciseRepository != null)
          exerciseRepositoryProvider.overrideWith(
            (_) async => exerciseRepository,
          ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WorkoutPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
